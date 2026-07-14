import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const OPENAI_MODEL = Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "content-type",
      },
    });
  }

  const url = new URL(req.url);
  const pathname = url.pathname.toLowerCase();
  const isAskRoute = pathname.endsWith("/coach-ai/ask") || pathname.endsWith("/coach_ai/ask") || pathname.endsWith("/ask");

  try {
    const body = await req.json().catch(() => ({}));
    const history = Array.isArray(body.history) ? body.history : [];
    const question = typeof body.question === "string" ? body.question.trim() : "";

    if (!OPENAI_API_KEY) {
      return new Response(
        JSON.stringify({
          recommendation: "Configura OPENAI_API_KEY para activar Coach AI.",
          reasoning: "La función no está configurada todavía, así que no puedo analizar el historial de entrenamiento.",
          advice: "Configura OPENAI_API_KEY para activar Coach AI.",
        }),
        {
          status: 200,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        },
      );
    }

    const prompt = `Eres un entrenador personal experto. Analiza este historial reciente de entrenamiento en formato JSON:
${JSON.stringify(history, null, 2)}

${question ? `La pregunta del usuario es: ${question}` : "Genera una recomendación general para la siguiente semana."}

Instrucciones estrictas:
- Responde SIEMPRE con un JSON válido con exactamente dos claves: "recommendation" y "reasoning".
- recommendation debe ser una frase breve, en español, que indique qué hacer.
- reasoning debe explicar por qué, citando datos concretos del historial recibido, como el volumen de la última semana, la ausencia de progreso en un ejercicio concreto, la frecuencia de sesiones o la distribución de cargas.
- Si faltan datos, menciona esa limitación de forma breve en reasoning.
- No uses markdown ni texto fuera del JSON.`;

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: OPENAI_MODEL,
        temperature: 0.7,
        messages: [{ role: "user", content: prompt }],
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`OpenAI error: ${response.status} ${errorText}`);
    }

    const data = await response.json();
    const content = data.choices?.[0]?.message?.content ?? "";
    let parsed: { recommendation?: string; reasoning?: string } | null = null;

    try {
      parsed = JSON.parse(content);
    } catch {
      const match = content.match(/\{[\s\S]*\}/);
      if (match) {
        try {
          parsed = JSON.parse(match[0]);
        } catch {
          // fallback below
        }
      }
    }

    const recommendation = parsed?.recommendation?.toString() ?? "Ajusta tu plan de entrenamiento para la próxima semana.";
    const reasoning = parsed?.reasoning?.toString() ?? "He usado el historial recibido para justificar la propuesta, pero no pude estructurar la respuesta en el formato esperado.";

    return new Response(JSON.stringify({ recommendation, reasoning, advice: `${recommendation}\n\n${reasoning}`, route: isAskRoute ? "ask" : "recommend" }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : String(error) }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      },
    );
  }
});

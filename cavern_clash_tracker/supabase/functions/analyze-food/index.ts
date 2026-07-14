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

  try {
    const body = await req.json().catch(() => ({}));
    const imageBase64 = typeof body.imageBase64 === "string" ? body.imageBase64 : "";
    const mimeType = typeof body.mimeType === "string" ? body.mimeType : "image/jpeg";
    const prompt = typeof body.prompt === "string" ? body.prompt : "Analiza la comida de la foto y estima alimentos, calorías y macronutrientes.";

    if (!OPENAI_API_KEY) {
      return new Response(
        JSON.stringify({
          foodName: "Comida detectada",
          calories: 420,
          protein: 24,
          carbs: 45,
          fat: 16,
          confidence: 0.5,
          reasoning: "La función no está configurada todavía. Se devuelve una estimación placeholder para que la UI siga funcionando.",
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

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: OPENAI_MODEL,
        temperature: 0.2,
        messages: [
          {
            role: "system",
            content: "Eres un experto nutricionista. Analiza la imagen y responde SOLO con JSON válido con las claves: foodName, calories, protein, carbs, fat, confidence, reasoning.",
          },
          {
            role: "user",
            content: [
              { type: "text", text: prompt },
              {
                type: "image_url",
                image_url: { url: `data:${mimeType};base64,${imageBase64}` },
              },
            ],
          },
        ],
      }),
    });

    if (!response.ok) {
      throw new Error(`OpenAI error: ${response.status} ${await response.text()}`);
    }

    const data = await response.json();
    const content = data.choices?.[0]?.message?.content ?? "{}";
    let parsed: Record<string, unknown> = {};

    try {
      parsed = JSON.parse(content);
    } catch {
      const match = content.match(/\{[\s\S]*\}/);
      if (match) {
        try {
          parsed = JSON.parse(match[0]);
        } catch {}
      }
    }

    return new Response(
      JSON.stringify({
        foodName: parsed.foodName ?? "Comida detectada",
        calories: Number(parsed.calories ?? 0),
        protein: Number(parsed.protein ?? 0),
        carbs: Number(parsed.carbs ?? 0),
        fat: Number(parsed.fat ?? 0),
        confidence: Number(parsed.confidence ?? 0.5),
        reasoning: parsed.reasoning ?? "Estimación generada a partir de la imagen.",
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      },
    );
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

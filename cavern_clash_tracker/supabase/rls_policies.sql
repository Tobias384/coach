-- RLS policies for user-scoped data in Supabase
-- Assumes each table has a user_id column and that the authenticated user id matches auth.uid().

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.routines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.routine_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.set_entries ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_profiles') THEN
    DROP POLICY IF EXISTS "user_profiles_select_own_rows" ON public.user_profiles;
    DROP POLICY IF EXISTS "user_profiles_insert_own_rows" ON public.user_profiles;
    DROP POLICY IF EXISTS "user_profiles_update_own_rows" ON public.user_profiles;
    DROP POLICY IF EXISTS "user_profiles_delete_own_rows" ON public.user_profiles;

    CREATE POLICY "user_profiles_select_own_rows"
      ON public.user_profiles
      FOR SELECT
      USING (auth.uid() = user_id);

    CREATE POLICY "user_profiles_insert_own_rows"
      ON public.user_profiles
      FOR INSERT
      WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "user_profiles_update_own_rows"
      ON public.user_profiles
      FOR UPDATE
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "user_profiles_delete_own_rows"
      ON public.user_profiles
      FOR DELETE
      USING (auth.uid() = user_id);
  END IF;

  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'routines') THEN
    DROP POLICY IF EXISTS "routines_select_own_rows" ON public.routines;
    DROP POLICY IF EXISTS "routines_insert_own_rows" ON public.routines;
    DROP POLICY IF EXISTS "routines_update_own_rows" ON public.routines;
    DROP POLICY IF EXISTS "routines_delete_own_rows" ON public.routines;

    CREATE POLICY "routines_select_own_rows"
      ON public.routines
      FOR SELECT
      USING (auth.uid() = user_id);

    CREATE POLICY "routines_insert_own_rows"
      ON public.routines
      FOR INSERT
      WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "routines_update_own_rows"
      ON public.routines
      FOR UPDATE
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "routines_delete_own_rows"
      ON public.routines
      FOR DELETE
      USING (auth.uid() = user_id);
  END IF;

  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'routine_exercises') THEN
    DROP POLICY IF EXISTS "routine_exercises_select_own_rows" ON public.routine_exercises;
    DROP POLICY IF EXISTS "routine_exercises_insert_own_rows" ON public.routine_exercises;
    DROP POLICY IF EXISTS "routine_exercises_update_own_rows" ON public.routine_exercises;
    DROP POLICY IF EXISTS "routine_exercises_delete_own_rows" ON public.routine_exercises;

    CREATE POLICY "routine_exercises_select_own_rows"
      ON public.routine_exercises
      FOR SELECT
      USING (auth.uid() = user_id);

    CREATE POLICY "routine_exercises_insert_own_rows"
      ON public.routine_exercises
      FOR INSERT
      WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "routine_exercises_update_own_rows"
      ON public.routine_exercises
      FOR UPDATE
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "routine_exercises_delete_own_rows"
      ON public.routine_exercises
      FOR DELETE
      USING (auth.uid() = user_id);
  END IF;

  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'workout_sessions') THEN
    DROP POLICY IF EXISTS "workout_sessions_select_own_rows" ON public.workout_sessions;
    DROP POLICY IF EXISTS "workout_sessions_insert_own_rows" ON public.workout_sessions;
    DROP POLICY IF EXISTS "workout_sessions_update_own_rows" ON public.workout_sessions;
    DROP POLICY IF EXISTS "workout_sessions_delete_own_rows" ON public.workout_sessions;

    CREATE POLICY "workout_sessions_select_own_rows"
      ON public.workout_sessions
      FOR SELECT
      USING (auth.uid() = user_id);

    CREATE POLICY "workout_sessions_insert_own_rows"
      ON public.workout_sessions
      FOR INSERT
      WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "workout_sessions_update_own_rows"
      ON public.workout_sessions
      FOR UPDATE
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "workout_sessions_delete_own_rows"
      ON public.workout_sessions
      FOR DELETE
      USING (auth.uid() = user_id);
  END IF;

  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'set_entries') THEN
    DROP POLICY IF EXISTS "set_entries_select_own_rows" ON public.set_entries;
    DROP POLICY IF EXISTS "set_entries_insert_own_rows" ON public.set_entries;
    DROP POLICY IF EXISTS "set_entries_update_own_rows" ON public.set_entries;
    DROP POLICY IF EXISTS "set_entries_delete_own_rows" ON public.set_entries;

    CREATE POLICY "set_entries_select_own_rows"
      ON public.set_entries
      FOR SELECT
      USING (auth.uid() = user_id);

    CREATE POLICY "set_entries_insert_own_rows"
      ON public.set_entries
      FOR INSERT
      WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "set_entries_update_own_rows"
      ON public.set_entries
      FOR UPDATE
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "set_entries_delete_own_rows"
      ON public.set_entries
      FOR DELETE
      USING (auth.uid() = user_id);
  END IF;
END $$;

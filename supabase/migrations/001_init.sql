create table if not exists public.profiles (
  id uuid primary key,
  email text unique,
  age integer,
  weight_kg numeric,
  sex text,
  activity_level text,
  created_at timestamptz default now()
);

create table if not exists public.meals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  source text not null,
  raw_input text,
  analysis jsonb,
  created_at timestamptz default now()
);

create table if not exists public.user_stats (
  user_id uuid primary key,
  energy integer default 50,
  sleep integer default 50,
  concentration integer default 50,
  updated_at timestamptz default now()
);

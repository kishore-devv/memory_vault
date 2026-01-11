-- Enable the pgvector extension to work with embedding vectors
create extension if not exists vector;

-- Create a table to store your documents
create table memories (
  id bigserial primary key,
  user_id uuid references auth.users not null,
  content text, -- corresponds to Document.pageContent
  metadata jsonb, -- corresponds to Document.metadata
  embedding vector(768), -- 768 is the default dimension for Gemini embeddings
  created_at timestamptz default now()
);

-- Enable Row Level Security (RLS)
alter table memories enable row level security;

-- Create a policy that allows users to only see their own memories
create policy "Users can view their own memories"
on memories for select
using ( auth.uid() = user_id );

create policy "Users can insert their own memories"
on memories for insert
with check ( auth.uid() = user_id );

-- Create a function to search for memories
create or replace function match_memories (
  query_embedding vector(768),
  match_threshold float,
  match_count int
)
returns table (
  id bigint,
  content text,
  similarity float
)
language plpgsql
as $$
begin
  return query
  select
    memories.id,
    memories.content,
    1 - (memories.embedding <=> query_embedding) as similarity
  from memories
  where 1 - (memories.embedding <=> query_embedding) > match_threshold
  order by memories.embedding <=> query_embedding
  limit match_count;
end;
$$;

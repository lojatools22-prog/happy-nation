-- Happy Nation · banco das aplicações (cole tudo no SQL Editor do Supabase e clique em Run)

create table if not exists public.aplicacoes (
  id uuid primary key default gen_random_uuid(),
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now(),
  nome text, whatsapp text unique, email text, cidade text,
  momento text, oab text, area text, renda text, trava text,
  motivo text, agenda text, investimento text,
  pontuacao int not null default 0,
  status text not null default 'novo' check (status in ('novo','chamado','em conversa','confirmado','não seguiu')),
  chamado_em timestamptz, observacoes text
);

alter table public.aplicacoes enable row level security;

-- Só o usuário do Bryan é administrador
create or replace function public.is_admin() returns boolean
language sql stable as $$
  select coalesce(lower(auth.jwt() ->> 'email') = 'bryansouza@happynationcriminal.com.br', false)
$$;

drop policy if exists adm_select on public.aplicacoes;
drop policy if exists adm_update on public.aplicacoes;
drop policy if exists adm_delete on public.aplicacoes;
create policy adm_select on public.aplicacoes for select to authenticated using (public.is_admin());
create policy adm_update on public.aplicacoes for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy adm_delete on public.aplicacoes for delete to authenticated using (public.is_admin());

-- Pontuação do perfil (quanto maior, mais prioridade no painel)
create or replace function public.calcula_pontuacao(d jsonb) returns int
language sql immutable as $$
  select
    (case d->>'momento'
      when 'Advogado(a) com até 1 ano de OAB' then 30
      when 'Advogado(a) de 1 a 3 anos' then 25
      when 'Bacharel, aguardando a OAB' then 18
      when 'Estudante do último ano' then 12
      when 'Advogado(a) há mais de 3 anos' then 15 else 0 end)
  + (case d->>'area'
      when 'Criminal' then 20
      when 'Outras áreas, quero ir para o criminal' then 18
      when 'Várias áreas ao mesmo tempo' then 12
      when 'Ainda não atuo' then 8 else 0 end)
  + (case d->>'agenda'
      when 'Sim, já reservei a data' then 20
      when 'Provavelmente sim' then 10 else 0 end)
  + (case d->>'investimento'
      when 'Sim, estou pronto(a)' then 25
      when 'Sim, dependendo das condições' then 12 else 0 end)
  + (case when length(coalesce(d->>'motivo','')) >= 80 then 5 else 0 end)
$$;

-- Recebe a aplicação do site (o visitante não consegue ler nada, só enviar)
create or replace function public.enviar_aplicacao(dados jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare zap text := regexp_replace(coalesce(dados->>'whatsapp',''), '\D', '', 'g');
begin
  if length(zap) < 10 or length(coalesce(dados->>'nome','')) < 2 then
    raise exception 'dados incompletos';
  end if;
  insert into aplicacoes (nome, whatsapp, email, cidade, momento, oab, area, renda, trava, motivo, agenda, investimento, pontuacao)
  values (left(dados->>'nome',120), zap, left(dados->>'email',160), left(dados->>'cidade',120),
          dados->>'momento', left(dados->>'oab',40), dados->>'area', dados->>'renda', dados->>'trava',
          left(dados->>'motivo',2000), dados->>'agenda', dados->>'investimento', calcula_pontuacao(dados))
  on conflict (whatsapp) do update set
    nome = excluded.nome, email = excluded.email, cidade = excluded.cidade, momento = excluded.momento,
    oab = excluded.oab, area = excluded.area, renda = excluded.renda, trava = excluded.trava,
    motivo = excluded.motivo, agenda = excluded.agenda, investimento = excluded.investimento,
    pontuacao = excluded.pontuacao, atualizado_em = now();
  return jsonb_build_object('ok', true);
end $$;

revoke all on function public.enviar_aplicacao(jsonb) from public;
grant execute on function public.enviar_aplicacao(jsonb) to anon, authenticated;
grant execute on function public.is_admin() to authenticated;
grant select, update, delete on public.aplicacoes to authenticated;

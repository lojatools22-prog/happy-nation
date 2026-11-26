# Happy Nation · Criminal Experience

Página de aplicação (filtro de leads e agregação de valor) da imersão com Bryan Souza, e painel do administrador.

- `index.html`: página pública. Envia a aplicação para o Supabase pela função `enviar_aplicacao`.
- `admin.html`: painel do Bryan (login pelo Supabase Auth). Lista, pontuação, status, observações, botão "Chamar no WhatsApp" e exportação CSV.
- `config.js`: URL do projeto Supabase e chave **anon public**. Nunca coloque a chave `service_role` aqui.
- `img/`: fotos e logos.

Hospedagem: GitHub Pages (branch `main`, pasta raiz).

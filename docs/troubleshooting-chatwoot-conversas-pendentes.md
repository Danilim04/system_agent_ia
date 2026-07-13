# Troubleshooting: mensagens do WhatsApp não aparecem no Chatwoot (instância Tiradentes)

**Data:** 2026-07-13
**Serviços envolvidos:** Evolution API (`app_evolution-api`), Chatwoot (`app_chatwoot-web` / `app_chatwoot-worker`)
**Instância Evolution:** `Tiradentes-Protecao` · **Inbox Chatwoot:** `Channel::Api`

> Identificadores de conta/inbox, IP do servidor e números de telefone foram omitidos/mascarados neste documento por serem dados de produção.

---

## 1. Sintoma relatado

Ao enviar uma mensagem de WhatsApp para o número da instância `Tiradentes-Protecao`, a mensagem **não aparecia** no painel do Chatwoot da conta Tiradentes. A caixa de entrada padrão (filtro `status=open`) mostrava apenas a conversa de teste inicial ("🚀 Connection successfully established!"), dando a impressão de que a integração estava quebrada.

---

## 2. Investigação

O diagnóstico foi feito acompanhando os logs dos dois serviços e o estado das conversas no Chatwoot enquanto mensagens de teste eram enviadas ao vivo.

### 2.1 A rede e a autenticação estavam OK
- A Evolution alcança o Chatwoot normalmente via HTTP: `http://chatwoot-web:3000` e `http://chatwoot-internal:3000` respondem.
- O `token` (access token) configurado na integração é **válido** para a conta do Chatwoot e o inbox `Tiradentes-Protecao` (`Channel::Api`) existe e está correto.

### 2.2 A Evolution RECEBE e REPASSA a mensagem
Ao enviar uma mensagem de teste, os logs da Evolution mostraram o fluxo completo funcionando:

```
[BaileysMessageProcessor] Processing batch of 1 messages
[Tiradentes-Protecao] [messages.upsert] New message received
[ChatwootService] --- Start createConversation ---
[ChatwootService] Found conversation to: <contato>@s.whatsapp.net, conversation ID: <id>
[ChannelStartupService] chatwootMessageId: <id>, chatwootInboxId: <inbox>, chatwootConversationId: <id>
```

Ou seja, a mensagem chegou até a API do Chatwoot **com sucesso** (mensagem criada, `chatwootMessageId` retornado).

### 2.3 A mensagem ESTAVA no Chatwoot — em status "pending"
Consultando a API do Chatwoot, a mensagem estava gravada na conta / inbox corretos, mas a conversa estava com **`status: "pending"`**:

- `GET /api/v1/accounts/<conta>/conversations?status=open` → retornava só a conversa de teste (status `open`).
- `GET /api/v1/accounts/<conta>/conversations?status=pending` → retornava **4 conversas reais** presas em pendente, incluindo as mensagens de teste.

O painel padrão do Chatwoot lista apenas conversas **Abertas**; as **Pendentes** ficam em uma aba separada. Por isso parecia que "nada chegava".

---

## 3. Causa raiz

A integração Evolution ↔ Chatwoot da instância `Tiradentes-Protecao` estava com a opção:

```
conversationPending = true
```

Com essa opção ativa, **toda conversa nova/reaberta entra como "Pendente"** em vez de "Aberta". Como os atendentes acompanham apenas a lista de conversas Abertas, as mensagens ficavam invisíveis, acumulando na aba Pendentes.

> **Importante:** não havia falha de entrega, roteamento ou configuração de token/inbox. O único fator era o **status inicial** aplicado às conversas.

---

## 4. Correção aplicada

Desativada a opção **"Conversa pendente" (`conversationPending`)** na configuração da integração Evolution ↔ Chatwoot da instância `Tiradentes-Protecao`. A partir disso, novas conversas entram diretamente como **Aberto** e aparecem na caixa de entrada padrão.

### Ação complementar recomendada
As conversas que já ficaram presas em **Pendente** precisam ser movidas manualmente para **Aberto** (ou respondidas) — filtrando a inbox por status **Pendentes** no painel do Chatwoot.

---

## 5. Achado secundário (não relacionado ao sintoma)

Nos logs da Evolution aparecem erros recorrentes:

```
ERROR [unhandledRejection] Error: getaddrinfo ENOTFOUND host  (pg-pool)
```

Causa: a variável `CHATWOOT_IMPORT_DATABASE_CONNECTION_URI` **não está configurada**, então a Evolution usa o hostname placeholder padrão `host`, que não resolve.

Impacto: afeta **apenas** o recurso de **importar histórico** de mensagens do Chatwoot (`importMessages=true`); **não** interfere na entrega de mensagens novas. Se o import de histórico não for usado, pode-se ignorar ou desativar `importMessages`. Caso seja necessário, configurar a URI apontando para o Postgres do Chatwoot.

---

## 6. Resumo

| Item | Situação |
|------|----------|
| Recebimento no WhatsApp (Evolution) | ✅ Funcionando |
| Repasse Evolution → API Chatwoot | ✅ Funcionando |
| Roteamento (conta / inbox / token) | ✅ Correto |
| Visibilidade no painel | ❌ Conversas caíam em **Pendente** → corrigido com `conversationPending = false` |
| Erro `ENOTFOUND host` (import DB) | ⚠️ Secundário, não afeta mensagens novas |

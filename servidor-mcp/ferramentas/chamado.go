package ferramentas

import (
	"context"
	"fmt"

	"github.com/mark3labs/mcp-go/mcp"
)

// ObterFerramentaAbrirChamado retorna a definição da ferramenta
func ObterFerramentaAbrirChamado() mcp.Tool {
	return mcp.Tool{
		Name:        "open_ticket",
		Description: "Abrir um chamado de suporte e encaminhar para atendimento humano. Use esta ferramenta quando o usuário solicitar atendimento humano ou quando a IA não souber a resposta.",
		InputSchema: mcp.ToolInputSchema{
			Type: "object",
			Properties: map[string]interface{}{
				"assunto": map[string]interface{}{
					"type":        "string",
					"description": "Resumo do problema relatado pelo cliente",
				},
				"prioridade": map[string]interface{}{
					"type":        "string",
					"description": "Prioridade do chamado (Baixa, Média, Alta)",
					"enum":        []string{"Baixa", "Média", "Alta"},
				},
				"resumo_conversa": map[string]interface{}{
					"type":        "string",
					"description": "Resumo do que foi conversado até agora para contexto do atendente",
				},
			},
			Required: []string{"assunto", "resumo_conversa"},
		},
	}
}

// HandlerAbrirChamado executa a ferramenta
func HandlerAbrirChamado(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	assunto, _ := request.RequireString("assunto")
	resumo, _ := request.RequireString("resumo_conversa")

	// Mock implementation for ticket creation
	ticketID := "CHAMADO-1234"

	msg := fmt.Sprintf("Chamado aberto com sucesso!\nID: %s\nAssunto: %s\n\nContexto enviado para o suporte: %s", ticketID, assunto, resumo)

	return mcp.NewToolResultText(msg), nil
}

package ferramentas

import (
	"context"
	"fmt"
	"time"

	"github.com/mark3labs/mcp-go/mcp"
)

// ObterFerramentaBuscaFatura retorna a definição da ferramenta
func ObterFerramentaBuscaFatura() mcp.Tool {
	return mcp.Tool{
		Name:        "search_invoice",
		Description: "Pesquisar informações sobre uma nota fiscal (NF) no sistema. Retorna status, valor e data.",
		InputSchema: mcp.ToolInputSchema{
			Type: "object",
			Properties: map[string]interface{}{
				"numero_nf": map[string]interface{}{
					"type":        "string",
					"description": "O número da nota fiscal a ser pesquisada",
				},
				"cnpj": map[string]interface{}{
					"type":        "string",
					"description": "CNPJ do emitente ou destinatário (opcional)",
				},
			},
			Required: []string{"numero_nf"},
		},
	}
}

// HandlerBuscaFatura executa a ferramenta
func HandlerBuscaFatura(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	numeroNF, err := request.RequireString("numero_nf")
	if err != nil {
		return mcp.NewToolResultError("O argumento 'numero_nf' é obrigatório e deve ser uma string."), nil
	}

	// Mock implementation
	// In a real scenario, this would query the database
	result := fmt.Sprintf(
		"Nota Fiscal encontrada:\nNúmero: %s\nStatus: AUTORIZADA\nValor: R$ 1.500,00\nData Emissão: %s\nEmitente: XPTO LTDA",
		numeroNF,
		time.Now().Format("02/01/2006"),
	)

	return mcp.NewToolResultText(result), nil
}

package ferramentas

import (
	"context"
	"fmt"

	"github.com/mark3labs/mcp-go/mcp"
)

// ObterFerramentaBuscaDocs retorna a definição da ferramenta
func ObterFerramentaBuscaDocs() mcp.Tool {
	return mcp.Tool{
		Name:        "search_docs",
		Description: "Pesquisar na base de conhecimento (documentação) da empresa. Use para responder dúvidas sobre o sistema.",
		InputSchema: mcp.ToolInputSchema{
			Type: "object",
			Properties: map[string]interface{}{
				"query": map[string]interface{}{
					"type":        "string",
					"description": "A pergunta ou termo de busca",
				},
			},
			Required: []string{"query"},
		},
	}
}

// HandlerBuscaDocs executa a ferramenta
func HandlerBuscaDocs(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	query, err := request.RequireString("query")
	if err != nil {
		return mcp.NewToolResultError("Argumento 'query' obrigatório."), nil
	}

	// TODO: Implementar Busca em Banco Vetorial (pgvector)
	// Por enquanto, retorna um placeholder baseado na query

	result := fmt.Sprintf("Informação encontrada na documentação sobre '%s':\n\n(Texto extraído do PDF da documentação seria retornado aqui...)", query)

	return mcp.NewToolResultText(result), nil
}

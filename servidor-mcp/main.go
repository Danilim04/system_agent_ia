package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/Danilim04/system_agent_ia/servidor-mcp/ferramentas"
	"github.com/mark3labs/mcp-go/server"
)

func main() {
	// Cria o servidor MCP
	s := server.NewMCPServer(
		"Agente MCP Server",
		"1.0.0",
	)

	// Registra ferramentas
	s.AddTool(ferramentas.ObterFerramentaBuscaFatura(), ferramentas.HandlerBuscaFatura)
	s.AddTool(ferramentas.ObterFerramentaAbrirChamado(), ferramentas.HandlerAbrirChamado)
	s.AddTool(ferramentas.ObterFerramentaBuscaDocs(), ferramentas.HandlerBuscaDocs)

	// Inicia o servidor via stdio (ou SSE para conexões remotas/docker)
	// Como estamos rodando em docker e conectando com N8N, HTTP/SSE é preferível.

	// Handlers HTTP para uso genérico no N8N (integração facilitada)
	http.HandleFunc("/api/fatura", func(w http.ResponseWriter, r *http.Request) {
		// Extrai params e chama lógica (Simplificado)
		numero := r.URL.Query().Get("numero_nf")
		result := fmt.Sprintf("Nota Fiscal %s encontrada (via HTTP API). Status: AUTORIZADA.", numero)
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"text": result})
	})

	http.HandleFunc("/api/chamado", func(w http.ResponseWriter, r *http.Request) {
		// Abertura de chamado simplificada
		var body map[string]string
		json.NewDecoder(r.Body).Decode(&body)
		result := fmt.Sprintf("Chamado aberto: %s. Prioridade: %s", body["assunto"], body["prioridade"])
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"text": result})
	})

	http.HandleFunc("/api/docs", func(w http.ResponseWriter, r *http.Request) {
		query := r.URL.Query().Get("query")
		result := fmt.Sprintf("Doc Info sobre: %s (via HTTP API)", query)
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"text": result})
	})

	log.Println("Iniciando Servidor MCP com API HTTP na porta :3001...")

	// Inicia SSE para MCP
	sseServer := server.NewSSEServer(s, server.WithBaseURL("http://localhost:3001"))
	http.Handle("/sse", sseServer.SSEHandler())
	http.Handle("/messages", sseServer.MessageHandler())

	if err := http.ListenAndServe(":3001", nil); err != nil {
		log.Fatalf("Erro no servidor: %v", err)
	}
}

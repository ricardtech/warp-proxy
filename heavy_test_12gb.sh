#!/bin/bash

# URLs de teste de download (usando arquivos grandes de 10GB ou múltiplos downloads)
# http://cachefly.cachefly.net/100mb.test (100MB) -> Faremos 120 downloads para totalizar 12GB
TEST_URL="http://cachefly.cachefly.net/100mb.test"
TOTAL_DOWNLOADS=120
TIMEOUT_PER_FILE=60
PROXY_HOST="127.0.0.1"
PORTS=(1080 1081 1082) # Mapeados para warp-proxy-1, 2, 3 no container host?
# Na verdade, o comando será rodado via docker exec ou usando o IP dos containers.

test_proxy() {
    local NAME=$1
    local PORT=$2
    local CONTAINER=$3
    
    echo "===================================================="
    echo "🚀 Iniciando teste de 12GB no $NAME ($CONTAINER)"
    echo "===================================================="
    
    COMPLETED=0
    FAILED=0
    START_TIME_TOTAL=$(date +%s)
    
    for ((i=1; i<=TOTAL_DOWNLOADS; i++)); do
        # echo -n "Download $i/$TOTAL_DOWNLOADS... "
        START_TIME_FILE=$(date +%s)
        
        # Teste via proxy dentro do container ou redirecionado
        # Usaremos docker exec para garantir que estamos saindo pelo container
        docker exec $CONTAINER curl -s -o /dev/null --max-time $TIMEOUT_PER_FILE $TEST_URL
        
        if [ $? -eq 0 ]; then
            ((COMPLETED++))
            # echo "OK"
        else
            ((FAILED++))
            echo "❌ Falha no download $i em $NAME"
            # Se falhar 3 vezes seguidas, podemos assumir que a conexão caiu
            if [ $FAILED -gt 5 ]; then
                echo "🛑 Conexão instável ou licença Free interrompida em $NAME."
                break
            fi
        fi
        
        if (( i % 10 == 0 )); then
            echo "📊 Progresso $NAME: $((i * 100 / TOTAL_DOWNLOADS))% ($((i * 100))MB baixados)"
        fi
    done
    
    END_TIME_TOTAL=$(date +%s)
    DURATION=$((END_TIME_TOTAL - START_TIME_TOTAL))
    
    echo "----------------------------------------------------"
    echo "✅ Fim do teste em $NAME"
    echo "Sucesso: $COMPLETED | Falha: $FAILED"
    echo "Tempo Total: ${DURATION}s"
    echo "===================================================="
}

# Verificar se os containers estão rodando
for i in 1 2 3; do
    CONTAINER="warp-proxy-$i"
    if ! docker ps | grep -q $CONTAINER; then
        echo "❌ Container $CONTAINER não encontrado!"
        exit 1
    fi
done

# Rodar testes (sequencial para não saturar a CPU do host, mas testando a cota individual)
test_proxy "Proxy 1" 1080 "warp-proxy-1"
test_proxy "Proxy 2" 1081 "warp-proxy-2"
test_proxy "Proxy 3" 1082 "warp-proxy-3"

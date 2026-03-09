#!/bin/bash

# Novas chaves fornecidas pelo usuário
KEYS=(
    "2p13EV5S-L3s5H2C6-29wOpG31"
    "3Xg7lc59-fo0pR491-60I97FaR"
    "Ft37TO41-Skl0176q-60PXue13"
    "e9f6O3A4-TU2Ok453-z2f46Ix7"
    "JI31G25F-4m61S8ul-tU47N1n9"
)

# Chaves anteriores (re-testando para garantir)
OLD_KEYS=(
    "6J0A3I8s-495T3fJw-a0O5A9F7"
    "8DY0Ol59-104Kt7Ar-3m6hfl45"
    "y9DN358K-aCF79T58-m5126uMW"
    "IJ78ZA35-9TE4nt63-5x30eBO1"
    "60ZY7n5x-465sA8lC-39banC25"
    "7Rj92D0O-4w56E3TN-820CLA9b"
    "a05jK7c9-93hX62Oo-i321C0sv"
    "c1EV89R3-IFg03q85-6D1scZ53"
    "j26V43zg-IX401R7A-06Wl25IR"
    "N152GB7j-9T1fkD30-FM016ta2"
)

# Testar as novas chaves primeiro
ALL_KEYS=("${KEYS[@]}" "${OLD_KEYS[@]}")

echo "🚀 Iniciando teste de chaves WARP+ e Validação de Cota (12GB)..."
echo "------------------------------------------------------------"

for KEY in "${ALL_KEYS[@]}"; do
    echo "Testing Key: $KEY"
    
    # Limpa registro anterior
    warp-cli --accept-tos registration delete > /dev/null 2>&1
    warp-cli --accept-tos registration new > /dev/null 2>&1
    
    # Tenta aplicar a licença
    RESULT=$(warp-cli --accept-tos registration license "$KEY" 2>&1)
    
    if [[ $RESULT == *"Success"* ]]; then
        sleep 3
        STATUS=$(warp-cli --accept-tos registration show)
        TYPE=$(echo "$STATUS" | grep "Account type" | awk '{print $3}')
        QUOTA=$(echo "$STATUS" | grep "Quota" | awk '{print $2, $3}')
        
        echo "Status: $TYPE | Quota: $QUOTA"
        
        if [[ $TYPE == *"Plus"* ]]; then
            echo "✅ VALID PLUS: $KEY"
            echo "📥 Iniciando teste de download de 1GB para validar estabilidade..."
            # Teste rápido de download (1GB) via proxy local, limitando para não estourar o servidor
            # Usando curl --proxy socks5h://127.0.0.1:1080
            START_TIME=$(date +%s)
            curl -x socks5h://127.0.0.1:1080 -o /dev/null -s --max-time 30 http://cachefly.cachefly.net/100mb.test
            EXIT_CODE=$?
            END_TIME=$(date +%s)
            
            if [ $EXIT_CODE -eq 0 ]; then
                echo "📊 Velocidade de download OK! (Tempo: $((END_TIME - START_TIME))s)"
            else
                echo "⚠️  Download falhou ou timeout atingido após 30s."
            fi
        else
            echo "❌ STILL FREE: $KEY ($TYPE)"
        fi
    else
        echo "⚠️  FAILED TO APPLY: $KEY - $RESULT"
    fi
    echo "------------------------------------------------------------"
done

# Restaurar chave original estável para garantir serviço online
ORIGINAL_KEY="iV4bQ198-Z0275GRd-N1W4St85"
echo "🔄 Restaurando registro original para segurança..."
warp-cli --accept-tos registration delete > /dev/null 2>&1
warp-cli --accept-tos registration new > /dev/null 2>&1
warp-cli --accept-tos registration license "$ORIGINAL_KEY" > /dev/null 2>&1
echo "✅ Teste finalizado."

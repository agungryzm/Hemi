#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 6

ARCH=$(uname -m)

tampilkan() {
    echo -e "\033[1;35m$1\033[0m"
}

# Pastikan jq terinstal
if ! command -v jq &> /dev/null; then
    tampilkan "jq tidak ditemukan, menginstal..."
    sudo apt-get update
    sudo apt-get install -y jq > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        tampilkan "Gagal menginstal jq. Silakan periksa manajer paket Anda."
        exit 1
    fi
fi

# URL versi terbaru
VERSI_TERBARU="v0.5.0"
HEMI_URL="https://github.com/hemilabs/heminetwork/releases/download/$VERSI_TERBARU/heminetwork_${VERSI_TERBARU}_linux_amd64.tar.gz"

unduh_diperlukan=true

# Cek apakah direktori sudah ada untuk arsitektur x86_64
if [ "$ARCH" == "x86_64" ]; then
    if [ -d "heminetwork_${VERSI_TERBARU}_linux_amd64" ]; then
        tampilkan "Versi terbaru untuk x86_64 sudah diunduh. Melewati unduhan."
        cd "heminetwork_${VERSI_TERBARU}_linux_amd64" || { tampilkan "Gagal masuk ke direktori."; exit 1; }
        unduh_diperlukan=false
    fi
fi

# Unduh dan ekstrak jika diperlukan
if [ "$unduh_diperlukan" = true ]; then
    tampilkan "Mengunduh untuk arsitektur x86_64..."
    wget --quiet --show-progress "$HEMI_URL" -O "heminetwork_${VERSI_TERBARU}_linux_amd64.tar.gz"
    tar -xzf "heminetwork_${VERSI_TERBARU}_linux_amd64.tar.gz" > /dev/null
    cd "heminetwork_${VERSI_TERBARU}_linux_amd64" || { tampilkan "Gagal masuk ke direktori."; exit 1; }
else
    tampilkan "Melewati unduhan karena versi terbaru sudah ada."
fi

# Menu pilihan
echo
tampilkan "Pilih hanya satu opsi:"
tampilkan "1. Buat Wallet Baru (direkomendasikan)"
tampilkan "2. Gunakan wallet yang sudah ada"
read -p "Masukkan pilihan Anda (1/2): " pilihan
echo

if [ "$pilihan" == "1" ]; then
    tampilkan "Membuat wallet baru..."
    ./keygen -secp256k1 -json -net="testnet" > ~/popm-address.json
    if [ $? -ne 0 ]; then
        tampilkan "Gagal membuat wallet."
        exit 1
    fi
    cat ~/popm-address.json
    echo
    read -p "Apakah Anda sudah menyimpan detail di atas? (y/N): " tersimpan
    echo
    if [[ "$tersimpan" =~ ^[Yy]$ ]]; then
        pubkey_hash=$(jq -r '.pubkey_hash' ~/popm-address.json)
        tampilkan "Bergabung : https://discord.gg/hemixyz"
        tampilkan "Minta faucet dari saluran faucet untuk alamat ini: $pubkey_hash"
        echo
        read -p "Apakah Anda sudah meminta faucet? (y/N): " faucet_diminta
        if [[ "$faucet_diminta" =~ ^[Yy]$ ]]; then
            priv_key=$(jq -r '.private_key' ~/popm-address.json)
            read -p "Masukkan biaya statis (hanya numerik, direkomendasikan: 100-200): " biaya_statis
            echo
            export POPM_BTC_PRIVKEY="$priv_key"
            export POPM_STATIC_FEE="$biaya_statis"
            export POPM_BFG_URL="wss://testnet.rpc.hemi.network/v1/ws/public"
            
            screen -dmS airdropnode ./popmd
            if [ $? -ne 0 ]; then
                tampilkan "Gagal memulai PoP mining dalam sesi screen terpisah."
                exit 1
            fi

            tampilkan "PoP mining telah dimulai dalam sesi screen terpisah bernama 'airdropnode'."
        fi
    fi

elif [ "$pilihan" == "2" ]; then
    read -p "Masukkan Private key Anda: " priv_key
    read -p "Masukkan biaya statis (hanya numerik, direkomendasikan: 100-200): " biaya_statis
    echo
    export POPM_BTC_PRIVKEY="$priv_key"
    export POPM_STATIC_FEE="$biaya_statis"
    export POPM_BFG_URL="wss://testnet.rpc.hemi.network/v1/ws/public"
    
    screen -dmS airdropnode ./popmd
    if [ $? -ne 0 ]; then
        tampilkan "Gagal memulai PoP mining dalam sesi screen terpisah."
        exit 1
    fi

    tampilkan "PoP mining telah dimulai dalam sesi screen terpisah bernama 'airdropnode'."
else
    tampilkan "Pilihan tidak valid."
    exit 1
fi

echo -e "\033[1;35m Bergabung dengan airdrop node https://t.me/airdrop_node \033[0m"

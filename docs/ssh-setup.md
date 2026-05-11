# SSH Setup — Como conectar ao servidor

## Pré-requisitos

- Acesso à VPN do projeto (se aplicável)
- Credenciais do servidor (usuário + senha ou chave SSH)
- Terminal com cliente SSH (Windows Terminal, PowerShell, Git Bash, ou qualquer Linux/Mac)

---

## 1. Conectar via senha

```bash
ssh grupo3@IP_DO_SERVIDOR
```

Substitua `IP_DO_SERVIDOR` pelo IP real. Será pedida a senha.

---

## 2. Configurar chave SSH (recomendado — evita digitar senha toda vez)

### 2.1 Gerar chave (na sua máquina local)

**Windows (PowerShell ou Git Bash):**
```bash
ssh-keygen -t ed25519 -C "seu-email@exemplo.com"
```

Aceite o caminho padrão (`~/.ssh/id_ed25519`). Defina uma passphrase ou deixe vazio.

**Linux/Mac:**
```bash
ssh-keygen -t ed25519 -C "seu-email@exemplo.com"
```

### 2.2 Copiar a chave pública para o servidor

**Linux/Mac:**
```bash
ssh-copy-id grupo3@IP_DO_SERVIDOR
```

**Windows (não tem ssh-copy-id):**
```powershell
# Copiar manualmente
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh grupo3@IP_DO_SERVIDOR "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

Ou manualmente:
1. Copie o conteúdo de `~/.ssh/id_ed25519.pub`
2. No servidor, adicione ao arquivo `~/.ssh/authorized_keys`

### 2.3 Testar

```bash
ssh grupo3@IP_DO_SERVIDOR
# Deve conectar sem pedir senha
```

---

## 3. Simplificar com SSH config (opcional)

Crie/edite o arquivo `~/.ssh/config`:

```
Host desafio
    HostName IP_DO_SERVIDOR
    User grupo3
    IdentityFile ~/.ssh/id_ed25519
```

Agora pode conectar apenas com:
```bash
ssh desafio
```

---

## 4. Usar com VPN

Se o servidor está atrás de uma VPN:

1. Conecte na VPN primeiro
2. Depois faça SSH normalmente

```bash
# Passo 1: conectar VPN (depende do seu cliente — OpenVPN, WireGuard, etc.)
# Passo 2: SSH
ssh desafio
```

---

## 5. Configurar SSH do GitHub no servidor (para git pull de repo privado)

O `scripts/deploy.sh` faz `git pull` no servidor. Se o repositório é privado, o servidor precisa de autenticação com o GitHub. A forma mais segura é uma **deploy key** (chave SSH exclusiva para leitura).

### 5.1 Gerar chave no servidor (dedicada ao GitHub)

```bash
# No servidor (logado como grupo3)
ssh-keygen -t ed25519 -C "deploy-key-desafio-fcg3" -f ~/.ssh/github_deploy
```

Deixe a passphrase vazia (para que o script rode sem interação).

### 5.2 Configurar o SSH do servidor para usar essa chave com o GitHub

```bash
nano ~/.ssh/config
```

Adicionar:
```
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_deploy
    IdentitiesOnly yes
```

Ajustar permissões:
```bash
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/github_deploy
```

### 5.3 Registrar a chave no GitHub

Copiar a chave pública:
```bash
cat ~/.ssh/github_deploy.pub
```

No GitHub:
- **Opção A (Deploy Key — recomendada)**: Repositório → Settings → Deploy keys → Add deploy key
  - Título: `servidor-desafio-fcg3`
  - Colar a chave pública
  - **Não** marcar "Allow write access" (só precisa de leitura)
  - Quem adiciona: o dono do repositório ou alguém com acesso admin

- **Opção B (sua conta pessoal)**: Settings → SSH and GPG keys → New SSH key
  - Funciona mas dá acesso a todos os seus repos — menos seguro

### 5.4 Testar conexão

```bash
ssh -T git@github.com
# Deve retornar: "Hi <user>! You've successfully authenticated..."
```

### 5.5 Clonar usando SSH (não HTTPS)

```bash
git clone git@github.com:ORGANIZACAO/REPOSITORIO.git /home/grupo3/desafio-fcg3
```

Se já clonou com HTTPS, troque o remote:
```bash
cd /home/grupo3/desafio-fcg3
git remote set-url origin git@github.com:ORGANIZACAO/REPOSITORIO.git
git pull  # Testar
```

### 5.6 Quem precisa fazer o quê

| Ação | Quem faz |
|------|----------|
| Gerar chave no servidor (5.1, 5.2) | Você (acesso SSH ao servidor) |
| Adicionar deploy key no GitHub (5.3) | Dono do repositório ou admin |
| Clonar/trocar remote (5.5) | Você |

Se você não é admin do repo, envie a chave pública (`github_deploy.pub`) para quem é e peça para adicionar como deploy key.

---

## 6. Transferir arquivos (SCP)

### Enviar arquivo para o servidor

```bash
# Arquivo único
scp arquivo.tar.gz grupo3@IP_DO_SERVIDOR:/tmp/

# Diretório inteiro
scp -r mobile/build/web grupo3@IP_DO_SERVIDOR:/tmp/flutter-web/
```

### Com SSH config:

```bash
scp arquivo.tar.gz desafio:/tmp/
scp -r mobile/build/web desafio:/tmp/flutter-web/
```

---

## 7. Workflow de deploy

Após configurar SSH, o deploy completo é:

```bash
# 1. Conectar (VPN + SSH)
ssh desafio

# 2. Rodar o script de deploy
cd /home/grupo3/desafio-fcg3
sudo bash scripts/deploy.sh

# 3. Escolher a ação no menu (ex: 1 para atualizar repo)
```

Para atualizar o Flutter Web:

```bash
# Na sua máquina local — buildar
cd mobile
flutter build web --release --dart-define=API_BASE_URL=https://seudominio.com/api/v1

# Enviar para o servidor
cd build
tar -czf /tmp/flutter-web.tar.gz web/
scp /tmp/flutter-web.tar.gz desafio:/tmp/

# No servidor — deployar
ssh desafio
cd /home/grupo3/desafio-fcg3
sudo bash scripts/deploy.sh
# Escolher opção 8 (Deploy Flutter Web)
```

---

## 8. Troubleshooting

### "Connection refused"
- VPN não está conectada
- Servidor desligado
- Firewall bloqueando porta 22

### "Permission denied (publickey)"
- Chave SSH não foi copiada corretamente
- Permissões erradas: `chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys` (no servidor)

### "Connection timed out"
- IP errado
- VPN não conectada
- Servidor em outra rede

### Verificar se a chave está sendo usada
```bash
ssh -v grupo3@IP_DO_SERVIDOR
# Procure por "Offering public key" no output verbose
```

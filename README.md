# rpcs3-config

Configs do RPCS3 (`config/`) versionadas: config global, configs por
jogo, perfis de controle. Não é o instalador nem ROM/BIOS/shader
cache/savestates — só a parte que muda quando você ajusta settings e
vale a pena ter histórico.

Feito e mantido a partir de uma instalação real (EmuDeck no Windows),
mas pensado pra ser reaproveitável em qualquer instalação de RPCS3.

## Uso rápido

Os scripts tentam auto-detectar o caminho do config do RPCS3 (locais
padrão do EmuDeck e do RPCS3 standalone). Se acharem, é só rodar sem
argumento nenhum; senão, passe o caminho na mão.

**Linux / macOS / WSL / Git Bash (com rsync):**

```bash
./scripts/sync.sh                              # tenta auto-detectar
./scripts/sync.sh /caminho/pro/rpcs3/config     # ou passa direto
git diff                                        # revisa o que mudou
git add -A && git commit -m "descreve o que mudou"
```

**Windows nativo (PowerShell, sem precisar instalar nada):**

```powershell
.\scripts\sync.ps1
.\scripts\sync.ps1 -ConfigDir "C:\caminho\pro\rpcs3\config"
```

Se o Windows bloquear a execução do `.ps1` (política de execução), rode:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync.ps1
```

Pra não digitar o caminho toda vez, copie `scripts/.env.example` para
`scripts/.env` (ignorado pelo git) e preencha `RPCS3_CONFIG_DIR` — os
scripts `.sh` leem esse arquivo automaticamente; no PowerShell, defina
`$env:RPCS3_CONFIG_DIR` na sessão.

## O que NÃO está aqui (de propósito)

- **`config/games.yml`** — mapeia serial do jogo → caminho absoluto da
  ROM no seu disco. 100% específico de máquina, sem valor pra outra
  pessoa, e expõe estrutura de pastas pessoal. Fica de fora
  (`.gitignore`).
- **`config/uuid`** — ID aleatório gerado por instalação, sem
  significado fora dela.
- **`config/vfs.yml`** — mapeia `/dev_hdd0/` e `/games/` pra caminhos
  absolutos do seu disco (ex.: letra de unidade no Windows). Mesma
  categoria de `games.yml`: específico de máquina, sem valor genérico.
- **`config/players_history.yml`** — histórico de jogadores encontrados
  via RPCN (multiplayer online). Vazio hoje, mas se você usar RPCN no
  futuro passa a conter PSN de **outras pessoas**, não só o seu — nunca
  deve ir pro repo, mesmo sem querer via sync.
- **Identificadores de "console virtual"** (`Console PSID`, `System
  Name`, `HDD Model Name/Serial`) — o `sync.sh` zera esses campos
  automaticamente a cada sync (por nome da chave, não por valor — o
  script não precisa saber o hardware/PSID de ninguém pra fazer isso).
- **Adapter de GPU fixado** (`Vulkan: Adapter`) — também zerado pelo
  sync. Com o campo vazio o RPCS3 auto-seleciona a GPU disponível, que
  é o comportamento padrão dele; isso é o que torna o config aplicável
  em qualquer PC sem edição manual. Se você quiser fixar numa GPU
  específica (útil só se tiver mais de uma no sistema), isso é uma
  escolha local sua — ajuste direto nas Settings do RPCS3, não neste
  repo.

Ou seja: `restore.sh` aplica um template genérico (bom pra bootstrap de
instalação nova, sua ou de outra pessoa), não é um backup pessoal
byte-a-byte. Se seu objetivo for desfazer seu próprio último
experimento local, use o histórico de commits + `git diff` pra ver
exatamente o que mudou, em vez de restaurar o snapshot completo.

## Estrutura

- `config/config.yml` — configuração global (usada por qualquer jogo sem config próprio)
- `config/custom_configs/` — overrides por jogo, ex.:
  - `config_BCUS98114.yml` — Gran Turismo 5
  - `config_BLUS30418.yml` — Red Dead Redemption
- `config/input_configs/` — perfis de controle/volante (ex.: `LogitechG27.yml`)
- `scripts/sync.sh` / `sync.ps1` — RPCS3 → repo (com sanitização automática)
- `scripts/restore.sh` / `restore.ps1` — repo → RPCS3 (pede confirmação, feche o RPCS3 antes)

## Ajustando pro seu hardware

Os valores de performance (Resolution Scale, SPU Block Size, Shader
Mode, Clocks scale) foram calibrados numa máquina com Ryzen 7 5700X
(8c/16t) / 32GB RAM / Radeon RX 9060 XT. Servem como ponto de partida
testado, não como valores universais — GPU mais fraca, considere
baixar a Resolution Scale antes de qualquer outra coisa; CPU mais
fraca, o principal impacto é em jogos world aberto pesados (ex. Red
Dead Redemption), não tanto nos ajustes de GPU.

**Versão do RPCS3 usada: 0.0.42-19697.** Vale conferir isso antes de
comparar campo a campo com o seu config — o schema desses YAML muda
entre versões (a gente descobriu isso na prática: o `config.yml`
global desse próprio repo estava com um schema de build anterior,
faltando chaves como `Use Re-BAR for GPU uploads` e `VSync Mode` que só
existiam no config por-jogo salvo depois de uma atualização do
emulador). Se algum campo daqui não existir na sua versão, ou existir
com outro nome, é provavelmente isso — não um erro de digitação.

## Onde fica o config/ real do RPCS3

- **EmuDeck (Windows)**: `%APPDATA%\EmuDeck\Emulators\RPCS3\config`
- **RPCS3 standalone (Windows)**: `%APPDATA%\rpcs3\config`
- **RPCS3 standalone (Linux/SteamOS)**: `~/.config/rpcs3`
- **EmuDeck (Linux/SteamOS)**: varia por versão/empacotamento
  (nativo vs Flatpak) — confira a documentação do EmuDeck pro seu caso

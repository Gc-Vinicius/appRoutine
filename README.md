# ⏰ appRoutine — App de Alarmes & Hábitos

Aplicativo Flutter focado em gerenciamento de rotinas com pontualidade estrita, capacidade de furar o *Doze Mode* (modo de hibernação da bateria do Android) e espelhamento confiável de alertas no smartwatch **Haylou Solar Neo**.

---

## 🚀 Funcionalidades Principais

* **Agendamento com Precisão de Segundos:** Utiliza `android_alarm_manager_plus` com modo `exactAllowWhileIdle`, acordando o processador no horário exato mesmo com o aparelho bloqueado há horas.
* **Espelhamento no Haylou Solar Neo:** Emissão de notificações locais nativas via canal prioritário (`Importance.max`), interceptado pelo aplicativo ponte (*Haylou Fun* ou *Hello Haylou*) e despachado via Bluetooth Low Energy (BLE) para o pulso.
* **Trava Ergonômica de Caracteres (RF02):**
  * Título: máx. **30 caracteres**
  * Mensagem: máx. **70 caracteres**
  * Evita quebras de linha indesejadas e corte de texto no mostrador circular AMOLED de 1.43".
* **3 Modalidades de Rotinas:**
  1. **Recorrente:** Horário fixo com seleção arbitrária de dias da semana (ex: Seg a Sex às 07:00).
  2. **Periódica:** Disparos intervalados dentro de uma janela definida (ex: a cada 2h das 08:00 às 20:00).
  3. **Pontual:** Alarme único com data e hora específicas (desativa-se automaticamente após o disparo).
* **3 Paletas de Cores Alternáveis (RF07):**
  * **Carmim & Pergaminho:** Fundo `#262525`, superfícies `#525252`, texto `#E6DDBC`, botões `#822626` (*Dark Academia*).
  * **Taiga Nórdica:** Fundo `#232226`, superfícies `#253342`, divisores `#3E5954`, botões `#5E9188` (*Moderno & Tech*).
  * **Brisa Costeira:** Fundo `#EBE7E0`, superfícies `#FFFFFF`, botões `#44749D`, chips `#C6D4E1` (*Minimalista & Clean*).
* **Painel de Diagnóstico do Sistema:**
  * Status e solicitação de permissões: `SCHEDULE_EXACT_ALARM`, `POST_NOTIFICATIONS` e `Isenção de Otimização de Bateria`.
  * Checklist de conectividade com o relógio.
  * Botão de teste imediato de vibração no pulso.

---

## 🛠️ Tecnologias Utilizadas

* **Framework:** Flutter (Android-first)
* **Gerenciamento de Estado:** `flutter_riverpod`
* **Persistência Local:** `drift` (SQLite tipado e seguro)
* **Agendamento em Segundo Plano:** `android_alarm_manager_plus`
* **Notificações:** `flutter_local_notifications`
* **Permissões:** `permission_handler` e `android_intent_plus`

---

## 📱 Protótipo no Figma

As especificações visuais e fluxos interativos de todas as 3 paletas e do relógio estão disponíveis no Figma.

# CipherPath Installation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Zainstalować zweryfikowany build CipherPath na własnym iPhonie bez publikowania aplikacji.

**Architecture:** Instalacja używa istniejącego projektu SwiftUI i standardowego podpisu Apple Development zarządzanego przez Xcode. Każdy etap obejmuje dokładnie 25% procesu i następny rozpoczyna się dopiero po pozytywnej kontroli poprzedniego.

**Tech Stack:** Xcode 27, Swift, SwiftUI, iOS 17+, Apple Development signing.

**Spec:** `docs/superpowers/specs/2026-09-12-toolbox-workflow-design.md`

## Global Constraints

- Instalacja tylko na własnym, świadomie podłączonym iPhonie.
- Bez publikacji w App Store, pushu, commita i zmian w NetScope.
- Bez `sudo`, dodatkowych pakietów Homebrew i omijania podpisu Apple.
- Następny etap rozpoczyna się wyłącznie po zaliczeniu kontroli bieżącego etapu.

---

### 0–25%: środowisko i projekt

- [x] Potwierdzić Xcode i aktywną ścieżkę narzędzi.
- [x] Potwierdzić projekt, target `CipherPath` i schemat `CipherPath`.
- [x] Sprawdzić dostępne urządzenia i tożsamości podpisujące.
- [x] Ustalić brakujące wymagania bez instalowania oprogramowania.

**Warunek przejścia:** Xcode rozpoznaje projekt i SDK. Wynik: spełniony.

### 25–50%: konto Apple i iPhone

- [x] Podłączyć iPhone’a i zaakceptować zaufanie do Maca.
- [ ] Włączyć Developer Mode na iPhonie, jeśli Xcode tego zażąda.
- [x] Potwierdzić Apple ID dostępne dla podpisu w Xcode.
- [x] Wybrać własny Team dla targetu CipherPath i pozostawić automatyczne podpisywanie.
- [x] Sprawdzić, czy Xcode pokazuje iPhone jako zgodne urządzenie docelowe.

**Warunek przejścia:** istnieje Apple Development identity, Team oraz rzeczywisty destination iOS.

### 50–75%: podpisany build

- [x] Zbudować konfigurację Debug dla podłączonego iPhone’a.
- [x] Potwierdzić `BUILD SUCCEEDED` bez błędów provisioning.
- [x] Sprawdzić bundle ID `pl.krystian.CipherPath` i podpis aplikacji.

**Warunek przejścia:** podpisany Debug build istnieje dla podłączonego urządzenia.

### 75–100%: instalacja i kontrola na telefonie

- [ ] Dokończyć instalację i uruchomienie przez Xcode na wybranym iPhonie; obecnie Xcode pozostaje na `Launching CipherPath`.
- [ ] Uruchomić CipherPath i zaakceptować tylko uzasadnione uprawnienie Local Network.
- [ ] Sprawdzić ekran startowy, Toolbox i katalog czterech lekcji offline.
- [ ] Potwierdzić, że NetScope i jego dane pozostały bez zmian.

**Warunek ukończenia:** CipherPath uruchamia się na iPhonie, a podstawowe ekrany działają bez awarii.

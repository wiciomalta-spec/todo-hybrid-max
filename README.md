# 📝 To-Do Hybrid MAX

**Zaawansowana aplikacja do zarządzania zadaniami z synchronizacją między Web a Desktop**

## 🎯 Cechy

- ✅ **Web App** - Dostęp przez przeglądarkę
- 💻 **Desktop App** - Okno desktopowe (Windows/Mac/Linux)
- 🔄 **Sync** - Automatyczna synchronizacja między Web i Desktop
- 💾 **Local Storage** - Dane przechowywane lokalnie
- 📊 **SQLite Database** - Trwałe przechowywanie danych
- 🎨 **Modern UI** - Nowoczesny interfejs z animacjami
- 📱 **Responsive** - Działa na wszystkich urządzeniach

## 📦 Wymagania

- Python 3.8+
- Node.js (opcjonalnie)
- Przeglądarka internetowa

## 🚀 Instalacja

### Web App
\\\ash
cd web
# Otwórz index.html w przeglądarce
# lub użyj lokalnego serwera:
python -m http.server 8000
# Otwórz http://localhost:8000
\\\

### Desktop App
\\\ash
pip install -r requirements.txt
python desktop/main.py
\\\

## 📋 Struktura Projektu

\\\
todo-hybrid-max/
├── web/
│   ├── index.html      # Main HTML
│   ├── styles.css      # Styling
│   ├── app.js          # App logic
│   ├── storage.js      # LocalStorage
│   └── sync.js         # Sync manager
├── desktop/
│   └── main.py         # PyQt5 Desktop App
├── shared/
│   └── sync_protocol.json
├── docs/
│   └── ARCHITECTURE.md
└── requirements.txt    # Python dependencies
\\\

## 🔄 Jak działa Sync?

1. **Web App** zapisuje dane w \localStorage\
2. **Desktop App** przechowuje dane w \SQLite\
3. Klikając \🔄 Sync\, dane się synchronizują
4. Zmiany na jednej platformie pojawią się na drugiej

## 🛠️ Technologie

- **Frontend**: HTML5, CSS3, JavaScript (Vanilla)
- **Backend**: Python, Flask
- **Desktop**: PyQt5
- **Database**: SQLite
- **Storage**: Browser LocalStorage

## 📝 Użycie

### Web App
1. Wpisz zadanie w pole input
2. Kliknij "Dodaj" lub naciśnij Enter
3. Zaznacz checkbox aby oznaczyć jako ukończone
4. Kliknij "Usuń" aby usunąć zadanie
5. Użyj "Sync" aby synchronizować z Desktop

### Desktop App
1. Uruchom \python desktop/main.py\
2. Interfejs jest taki sam jak Web
3. Automatycznie synchronizuje z Web App

## 🔐 Bezpieczeństwo

- Dane przechowywane lokalnie
- Brak wysyłania danych na zewnętrzne serwery
- Szyfrowanie opcjonalnie

## 📄 Licencja

MIT License - Wolna do użytku i modyfikacji

## 👤 Autor

wiciomalta-spec

---

**Wersja**: 1.0  
**Data**: 2026-04-11

# Promptly - Voice-Controlled Teleprompter

![Phoenix](https://img.shields.io/badge/Phoenix-1.7+-orange.svg)
![Elixir](https://img.shields.io/badge/Elixir-1.15+-purple.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

A modern teleprompter application with voice-control. Built with Phoenix LiveView for real-time responsiveness and featuring speech-recognition capabilities.

## Features

- **Voice-Controlled Scrolling**: Automatically scrolls text based on your reading pace
- **Real-Time Word Highlighting**: Current word follows your speech with visual feedback
- **Smart Pause Detection**: Stops scrolling when you pause, resumes when you continue
- **Multiple Input Methods**: Copy-paste text, upload PDF, TXT, and DOCX files
- **Customizable Settings**: Adjust scroll speed, text/font size, theme, etc.
- **Real-Time Processing**: Powered by Phoenix LiveView for instant responsiveness
- **Cross-Platform**: Works on desktop and mobile browsers
- **Professional UI**: Clean, modern interface optimized for reading

## Technology Stack

- **Backend**: Phoenix Framework (Elixir)
- **Frontend**: Tailwind CSS
- **Speech Recognition**: Web Speech API with fallback options
- **File Processing**: Custom parsers for PDF, DOCX, TXT

## Prerequisites

- Elixir 1.15+
- Phoenix 1.7+
- Node.js 18+

## Installation

1. Clone the repository:

```bash
git clone https://github.com/Kaybangz/Promptly
cd promptly
```

2. Install dependencies:

```bash
mix deps.get
cd assets && npm install && cd ..
```

3. Start the Phoenix server:

```bash
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000) to access the application.

## Usage

1. **Provide a Script**: Either write/paste text directly to the editor or upload a file
2. **Configure Settings**: Adjust scroll speed, text size, theme, or mirror mode
3. **Start Reading**: Click "Start" and start presenting
4. **Automatic Sync**: When scroll control is set to voice, the app will highlight current words and scroll automatically

## License

This project is licensed under the MIT License.

# Promptly - Voice-Controlled Teleprompter

![Phoenix](https://img.shields.io/badge/Phoenix-1.7+-orange.svg)
![Elixir](https://img.shields.io/badge/Elixir-1.15+-purple.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

A modern, voice-controlled teleprompter application that synchronizes text scrolling and highlighting with your natural reading pace. Built with Phoenix LiveView for real-time responsiveness and featuring advanced speech recognition capabilities.

## Features

- **Voice-Controlled Scrolling**: Automatically scrolls text based on your reading pace
- **Real-Time Word Highlighting**: Current word follows your speech with visual feedback
- **Smart Pause Detection**: Stops scrolling when you pause, resumes when you continue
- **Multiple Input Methods**: Copy-paste text, upload PDF, TXT, DOCX, and other text files
- **Customizable Settings**: Adjust scroll speed, text size, colors, and timing sensitivity
- **Real-Time Processing**: Powered by Phoenix LiveView for instant responsiveness
- **Cross-Platform**: Works on desktop and mobile browsers
- **Professional UI**: Clean, modern interface optimized for reading

## Technology Stack

- **Backend**: Phoenix Framework (Elixir)
- **Frontend**: Phoenix LiveView with Alpine.js
- **Real-Time**: Phoenix Channels + WebRTC
- **Speech Recognition**: Web Speech API with fallback options
- **File Processing**: Custom parsers for PDF, DOCX, TXT
- **Styling**: Tailwind CSS
- **Database**: PostgreSQL (for user preferences and scripts)

## Prerequisites

- Elixir 1.15+
- Phoenix 1.7+
- Node.js 18+
- PostgreSQL 14+

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

3. Set up the database:

```bash
mix ecto.create
```

4. Start the Phoenix server:

```bash
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000) to access the application.

## Usage

### Basic Usage

1. **Create a Script**: Either paste text directly or upload a file
2. **Configure Settings**: Adjust scroll speed, text size, and sensitivity
3. **Start Reading**: Click "Start" and begin reading aloud
4. **Automatic Sync**: The app will highlight current words and scroll automatically

### Advanced Features

- **Custom Timing**: Adjust pause detection sensitivity
- **Multiple Voices**: Support for different speech patterns
- **Script Management**: Save and organize multiple scripts
- **Export Options**: Export highlighted transcripts

## License

This project is licensed under the MIT License.

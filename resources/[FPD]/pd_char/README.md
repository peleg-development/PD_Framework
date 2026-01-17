# pd_char

Multi-character system for FivePD framework with React UI.

## Features

- Create multiple characters per player (configurable max slots)
- Character selection UI with React + TypeScript + Tailwind CSS
- Character creation form
- Character deletion
- Automatic character loading on player join
- Integration with pd_core player data system

## Requirements

- `pd_core` resource
- `pd_lib` resource
- SQL driver: `oxmysql` or `ghmattimysql`
- Node.js and npm (for building the UI)

## Installation

1. Ensure `pd_core` and `pd_lib` are installed and started
2. Add to server.cfg: `ensure pd_char`
3. Build the UI:
   ```bash
   cd web
   npm install
   npm run build
   ```
4. Restart the server

## Configuration

Edit `config.lua`:

```lua
Config = {
    database = {
        tablePrefix = 'pd_',
        charactersTable = 'characters'
    },
    maxCharacters = 5  -- Maximum characters per player
}
```

## Usage

### Server Exports

- `exports.pd_char:GetCharacters(source)` - Get all characters for a player
- `exports.pd_char:GetActiveCharacter(source)` - Get the currently selected character
- `exports.pd_char:SelectCharacter(source, slot)` - Select a character by slot
- `exports.pd_char:CreateCharacter(source, slot, data)` - Create a new character

### Client Exports

- `exports.pd_char:OpenSelection()` - Open the character selection UI
- `exports.pd_char:GetLocalCharacters()` - Get cached characters on client

### Events

**Server:**
- `pd_char:server:characterSelected` - Fired when a character is selected
  - Parameters: `source`, `character`

**Client:**
- `pd_char:client:characterSelected` - Fired when character selection completes
  - Parameters: `character`

## Character Data Structure

```lua
{
    id = number,
    identifier = string,
    slot = number,
    firstName = string,
    lastName = string,
    dateOfBirth = string,
    gender = string,
    appearance = table,
    metadata = table,
    createdAt = number,
    updatedAt = number
}
```

## Development

To develop the UI:

```bash
cd web
npm install
npm run dev
```

The UI will be available at `http://localhost:5173` for development.

To build for production:

```bash
npm run build
```

## Database Schema

The resource automatically creates the `pd_characters` table with the following structure:

- `id` - Auto-increment primary key
- `identifier` - Player identifier (license)
- `slot` - Character slot number (1-maxCharacters)
- `first_name` - Character first name
- `last_name` - Character last name
- `date_of_birth` - Date of birth string
- `gender` - Gender (male/female)
- `appearance` - JSON appearance data
- `metadata` - JSON metadata
- `created_at` - Unix timestamp
- `updated_at` - Unix timestamp

Unique constraint on `(identifier, slot)` ensures one character per slot per player.

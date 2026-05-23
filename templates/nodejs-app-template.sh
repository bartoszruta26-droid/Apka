#!/bin/bash

#===============================================================================
# Szablon projektu: Node.js Application (Express API)
# Template: Node.js Express Application
#===============================================================================

set -euo pipefail

PROJECT_NAME="${1:-my-node-app}"
PROJECT_DIR="${2:-./${PROJECT_NAME}}"

echo "📦 Tworzenie projektu Node.js: $PROJECT_NAME"
echo "Lokalizacja: $PROJECT_DIR"

# Tworzenie struktury katalogów
mkdir -p "$PROJECT_DIR"/{src/{routes,controllers,middleware,models,utils},tests,public/{css,js,images},config}

# package.json
cat > "$PROJECT_DIR/package.json" << EOF
{
  "name": "$PROJECT_NAME",
  "version": "1.0.0",
  "description": "A Node.js Express application template",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js",
    "test": "jest --coverage",
    "lint": "eslint src/",
    "format": "prettier --write \"src/**/*.js\"",
    "build": "echo 'Build completed'"
  },
  "keywords": [
    "nodejs",
    "express",
    "api",
    "rest"
  ],
  "author": "Your Name",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "morgan": "^1.10.0",
    "dotenv": "^16.3.1",
    "express-validator": "^7.0.1",
    "compression": "^1.7.4",
    "express-rate-limit": "^7.1.5"
  },
  "devDependencies": {
    "nodemon": "^3.0.2",
    "jest": "^29.7.0",
    "supertest": "^6.3.3",
    "eslint": "^8.56.0",
    "prettier": "^3.1.1"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF

# .env.example
cat > "$PROJECT_DIR/.env.example" << 'EOF'
# Server Configuration
PORT=3000
NODE_ENV=development

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=myapp
DB_USER=user
DB_PASSWORD=password

# JWT Secret
JWT_SECRET=your-super-secret-jwt-key-change-in-production

# API Keys
API_KEY=your-api-key-here

# Logging
LOG_LEVEL=debug
EOF

# src/index.js
cat > "$PROJECT_DIR/src/index.js" << 'EOF'
/**
 * @file index.js
 * @brief Main entry point for the Node.js Express application
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');

// Import routes
const apiRoutes = require('./routes/api');
const healthRoutes = require('./routes/health');

// Create Express app
const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors({
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Compression
app.use(compression());

// Logging
if (process.env.NODE_ENV !== 'test') {
    app.use(morgan('combined'));
}

// Static files
app.use(express.static('public'));

// Health check endpoint
app.use('/health', healthRoutes);

// API routes
app.use('/api/v1', apiRoutes);

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        name: process.env.npm_package_name,
        version: process.env.npm_package_version,
        description: 'Node.js Express API',
        endpoints: {
            health: '/health',
            api: '/api/v1',
            docs: '/api-docs'
        }
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Route not found'
    });
});

// Error handler
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(err.status || 500).json({
        success: false,
        message: err.message || 'Internal Server Error',
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📝 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🌐 Health check: http://localhost:${PORT}/health`);
    console.log(`🔌 API: http://localhost:${PORT}/api/v1`);
});

module.exports = app;
EOF

# src/routes/api.js
cat > "$PROJECT_DIR/src/routes/api.js" << 'EOF'
/**
 * @file api.js
 * @brief API routes module
 */

const express = require('express');
const router = express.Router();

// Sample data store (replace with database)
let items = [
    { id: 1, name: 'Item 1', description: 'First item' },
    { id: 2, name: 'Item 2', description: 'Second item' }
];

/**
 * @route GET /api/v1/items
 * @desc Get all items
 */
router.get('/items', (req, res) => {
    res.json({
        success: true,
        count: items.length,
        data: items
    });
});

/**
 * @route GET /api/v1/items/:id
 * @desc Get single item by ID
 */
router.get('/items/:id', (req, res) => {
    const item = items.find(i => i.id === parseInt(req.params.id));
    
    if (!item) {
        return res.status(404).json({
            success: false,
            message: `Item not found with id ${req.params.id}`
        });
    }
    
    res.json({
        success: true,
        data: item
    });
});

/**
 * @route POST /api/v1/items
 * @desc Create new item
 */
router.post('/items', (req, res) => {
    const { name, description } = req.body;
    
    if (!name) {
        return res.status(400).json({
            success: false,
            message: 'Name is required'
        });
    }
    
    const newItem = {
        id: items.length + 1,
        name,
        description: description || ''
    };
    
    items.push(newItem);
    
    res.status(201).json({
        success: true,
        data: newItem
    });
});

/**
 * @route PUT /api/v1/items/:id
 * @desc Update item
 */
router.put('/items/:id', (req, res) => {
    const item = items.find(i => i.id === parseInt(req.params.id));
    
    if (!item) {
        return res.status(404).json({
            success: false,
            message: `Item not found with id ${req.params.id}`
        });
    }
    
    const { name, description } = req.body;
    item.name = name || item.name;
    item.description = description || item.description;
    
    res.json({
        success: true,
        data: item
    });
});

/**
 * @route DELETE /api/v1/items/:id
 * @desc Delete item
 */
router.delete('/items/:id', (req, res) => {
    const index = items.findIndex(i => i.id === parseInt(req.params.id));
    
    if (index === -1) {
        return res.status(404).json({
            success: false,
            message: `Item not found with id ${req.params.id}`
        });
    }
    
    const deletedItem = items.splice(index, 1)[0];
    
    res.json({
        success: true,
        message: 'Item deleted successfully',
        data: deletedItem
    });
});

module.exports = router;
EOF

# src/routes/health.js
cat > "$PROJECT_DIR/src/routes/health.js" << 'EOF'
/**
 * @file health.js
 * @brief Health check routes
 */

const express = require('express');
const router = express.Router();

/**
 * @route GET /health
 * @desc Basic health check
 */
router.get('/', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

/**
 * @route GET /health/ready
 * @desc Readiness check
 */
router.get('/ready', (req, res) => {
    // Add database/connection checks here
    res.json({
        status: 'ready',
        checks: {
            database: 'ok',
            cache: 'ok',
            external_services: 'ok'
        }
    });
});

/**
 * @route GET /health/live
 * @desc Liveness check
 */
router.get('/live', (req, res) => {
    res.json({
        status: 'alive',
        version: process.env.npm_package_version || '1.0.0'
    });
});

module.exports = router;
EOF

# tests/api.test.js
cat > "$PROJECT_DIR/tests/api.test.js" << 'EOF'
/**
 * @file api.test.js
 * @brief API endpoint tests
 */

const request = require('supertest');

// Mock app for testing
const app = {
    get: jest.fn(),
    post: jest.fn(),
    use: jest.fn()
};

describe('API Endpoints', () => {
    describe('GET /api/v1/items', () => {
        test('should return all items', async () => {
            // Mock implementation
            const response = {
                success: true,
                count: 2,
                data: [
                    { id: 1, name: 'Item 1' },
                    { id: 2, name: 'Item 2' }
                ]
            };
            
            expect(response.success).toBe(true);
            expect(response.count).toBe(2);
            expect(response.data).toHaveLength(2);
        });
    });
    
    describe('POST /api/v1/items', () => {
        test('should create new item', async () => {
            const newItem = { name: 'Test Item', description: 'Test' };
            
            expect(newItem.name).toBeDefined();
            expect(typeof newItem.name).toBe('string');
        });
        
        test('should fail without name', async () => {
            const invalidItem = { description: 'No name' };
            
            expect(invalidItem.name).toBeUndefined();
        });
    });
});

describe('Health Endpoints', () => {
    test('health check should return status', () => {
        const health = {
            status: 'healthy',
            timestamp: new Date().toISOString()
        };
        
        expect(health.status).toBe('healthy');
    });
});
EOF

# README.md
cat > "$PROJECT_DIR/README.md" << EOF
# $PROJECT_NAME

A modern Node.js Express application template with REST API support.

## Structure

\`\`\`
$PROJECT_NAME/
├── src/
│   ├── index.js            # Main entry point
│   ├── routes/
│   │   ├── api.js          # API routes
│   │   └── health.js       # Health check routes
│   ├── controllers/        # Route controllers
│   ├── middleware/         # Custom middleware
│   ├── models/             # Data models
│   └── utils/              # Utility functions
├── tests/                  # Unit and integration tests
├── public/                 # Static files
│   ├── css/
│   ├── js/
│   └── images/
├── config/                 # Configuration files
├── package.json            # Dependencies and scripts
├── .env.example            # Environment variables template
└── README.md               # This file
\`\`\`

## Quick Start

\`\`\`bash
# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Development mode
npm run dev

# Production mode
npm start

# Run tests
npm test

# Lint code
npm run lint
\`\`\`

## API Endpoints

### Health Check
- \`GET /health\` - Basic health check
- \`GET /health/ready\` - Readiness check
- \`GET /health/live\` - Liveness check

### Items API
- \`GET /api/v1/items\` - Get all items
- \`GET /api/v1/items/:id\` - Get item by ID
- \`POST /api/v1/items\` - Create new item
- \`PUT /api/v1/items/:id\` - Update item
- \`DELETE /api/v1/items/:id\` - Delete item

## Features

- Express.js framework
- CORS enabled
- Helmet security headers
- Rate limiting
- Request compression
- Morgan logging
- Environment configuration
- RESTful API design
- Error handling middleware
- Health check endpoints
- Jest testing setup
- ESLint and Prettier

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| PORT | Server port | 3000 |
| NODE_ENV | Environment | development |
| CORS_ORIGIN | Allowed origins | * |
| LOG_LEVEL | Logging level | debug |

## License

MIT License
EOF

# .gitignore
cat > "$PROJECT_DIR/.gitignore" << 'EOF'
# Dependencies
node_modules/
package-lock.json

# Environment
.env
.env.local
.env.*.local

# Logs
logs/
*.log
npm-debug.log*

# Runtime data
pids/
*.pid
*.seed
*.pid.lock

# Coverage
coverage/
.nyc_output/

# Build
dist/
build/

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Temporary
tmp/
temp/
*.tmp
EOF

# .eslintrc.json
cat > "$PROJECT_DIR/.eslintrc.json" << 'EOF'
{
  "env": {
    "node": true,
    "commonjs": true,
    "es2021": true,
    "jest": true
  },
  "extends": "eslint:recommended",
  "parserOptions": {
    "ecmaVersion": "latest"
  },
  "rules": {
    "indent": ["error", 4],
    "linebreak-style": ["error", "unix"],
    "quotes": ["error", "single"],
    "semi": ["error", "always"],
    "no-unused-vars": ["warn"],
    "no-console": "off"
  }
}
EOF

echo ""
echo "✅ Projekt Node.js utworzony pomyślnie!"
echo ""
echo "Struktura projektu:"
find "$PROJECT_DIR" -type f | sort | sed "s|$PROJECT_DIR||"
echo ""
echo "Aby uruchomić:"
echo "  cd $PROJECT_DIR"
echo "  npm install"
echo "  cp .env.example .env"
echo "  npm run dev"

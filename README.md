# Robot Framework Project

A comprehensive Robot Framework test automation project with support for web UI testing, API testing, and database testing.

## Project Structure

```
robot_playground/
├── requirements.txt          # Python dependencies
├── robot.yaml               # Robot Framework configuration
├── Makefile                 # Automation commands
├── .env.example            # Environment variables template
├── .gitignore              # Git ignore rules
├── tests/
│   ├── api/                # API test suites
│   ├── gui/                # Web UI test suites
│   ├── db/                 # Database test suites
│   ├── data/               # Test data files
│   └── resources/          # Shared keywords and libraries
└── results/                # Test execution results (auto-generated)
```

## Getting Started

### Prerequisites

- Python 3.8 or higher
- Chrome/Firefox browser (for GUI tests)
- Make (optional, for using Makefile commands)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd robot_playground
```

2. Set up virtual environment and install dependencies:
```bash
make setup
# OR manually:
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

3. Copy environment configuration:
```bash
cp .env.example .env
# Edit .env with your actual configuration values
```

## Running Tests

### Using Makefile (Recommended)

```bash
# Run all tests
make test

# Run specific test types
make test-api      # API tests only
make test-gui      # GUI tests only
make test-db       # Database tests only
make test-security # Security tests only
make test-smoke    # Smoke tests only

# Run tests in parallel
make test-parallel

# Run tests with specific tags
make test-tag      # Will prompt for tag name

# Database setup (choose one based on your database)
make setup-db-postgres
make setup-db-mysql
make setup-db-mongodb

# Security testing with ZAP
make start-zap                # Instructions for starting ZAP
make test-security-with-zap   # Run security tests with ZAP proxy
```

### Using Robot Framework directly

```bash
# Run all tests
robot --outputdir results tests/

# Run specific test suites
robot --outputdir results tests/api/
robot --outputdir results tests/gui/
robot --outputdir results tests/db/
robot --outputdir results tests/security/

# Run tests with tags
robot --outputdir results --include smoke tests/
robot --outputdir results --exclude slow tests/
robot --outputdir results --include database tests/
robot --outputdir results --include security tests/

# Run tests in parallel
pabot --processes 4 --outputdir results tests/
```

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and configure:

- `BASE_URL`: Application base URL
- `API_BASE_URL`: API endpoint base URL
- `BROWSER`: Browser to use (chrome, firefox, safari)
- `HEADLESS`: Run browser in headless mode (true/false)
- Database connection settings (`DB_HOST`, `DB_PORT`, `DB_NAME`, etc.)
- API keys and authentication tokens
- `ZAP_PROXY`: OWASP ZAP proxy URL (leave empty to disable security testing)
- `ZAP_API_KEY`: ZAP API key for security testing

### Robot Framework Configuration

The `robot.yaml` file contains default Robot Framework settings:
- Output directory configuration
- Default variables
- Python path settings
- Logging levels

## Test Data

Test data is stored in `tests/data/` directory:
- `test_data.json`: Common test data in JSON format
- Add environment-specific data files as needed

## Database Testing

### Supported Databases

The framework supports multiple database types:
- **PostgreSQL** (default)
- **MySQL/MariaDB**
- **MongoDB**

### Database Configuration

Configure database connection in your `.env` file:

```bash
# PostgreSQL
DB_TYPE=postgresql
DB_HOST=localhost
DB_PORT=5432
DB_NAME=test_db
DB_USER=test_user
DB_PASSWORD=test_password

# MySQL
DB_TYPE=mysql
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_DB=test_db
MYSQL_USER=test_user
MYSQL_PASSWORD=test_password

# MongoDB
DB_TYPE=mongodb
MONGO_HOST=localhost
MONGO_PORT=27017
MONGO_DB=test_db
MONGO_USER=test_user
MONGO_PASSWORD=test_password
```

### Database Test Examples

```bash
# Run all database tests
make test-db

# Run specific database operations
robot --outputdir results --include crud tests/db/
robot --outputdir results --include transaction tests/db/
```

## Security Testing with OWASP ZAP

### ZAP Integration

The framework includes built-in OWASP ZAP integration for security testing:

1. **Proxy Configuration**: Automatically configures browsers and API clients to use ZAP proxy
2. **Spider Scanning**: Discovers application structure and endpoints
3. **Active Scanning**: Performs security vulnerability testing
4. **Report Generation**: Creates HTML and XML security reports
5. **CI/CD Integration**: Automated security testing in GitHub Actions

### ZAP Setup

1. **Install OWASP ZAP**:
   ```bash
   # Using Docker (recommended for CI/CD)
   docker run -d -p 8080:8080 owasp/zap2docker-stable zap-x.sh -daemon -host 0.0.0.0 -port 8080
   
   # Or install locally
   # Download from https://owasp.org/www-project-zap/
   ```

2. **Configure Environment**:
   ```bash
   # In your .env file
   ZAP_PROXY=http://localhost:8080
   ZAP_API_KEY=your_zap_api_key_here
   ENABLE_SECURITY_TESTS=true
   ```

3. **Run Security Tests**:
   ```bash
   # Start ZAP first
   make start-zap
   
   # Run security tests
   make test-security-with-zap
   ```

### Security Test Features

- **Conditional Execution**: Tests automatically skip if ZAP proxy is not configured
- **Comprehensive Scanning**: Spider scan + Active security scan
- **Vulnerability Detection**: Automatically fails tests on high-risk vulnerabilities
- **Multiple Report Formats**: HTML for viewing, XML for CI/CD processing
- **Browser & API Coverage**: Tests both web UI and API endpoints through proxy

## Custom Libraries

### TestUtils.py

Custom Python library with utility keywords:
- `Get Current Timestamp`: Generate ISO timestamp
- `Generate Test Data`: Create test data (emails, names, etc.)
- `Load Json Test Data`: Load test data from JSON files
- `Compare Json Objects`: Compare JSON with optional key exclusion

## Code Quality

### Linting and Formatting

```bash
# Run linting
make lint
robocop tests/

# Format code
make format
robotidy tests/
```

### Static Analysis Tools

The project includes:
- **Robocop**: Static code analysis for Robot Framework
- **Robot Tidy**: Code formatter for Robot Framework
- **Robot Metrics**: Enhanced test reporting

## Reporting

### Generate Reports

```bash
# Generate enhanced reports
make report

# Serve results on local web server
make serve
# Then visit http://localhost:8000
```

### Report Files

After test execution, find reports in `results/` directory:
- `report.html`: Test execution report
- `log.html`: Detailed test log
- `output.xml`: XML output for CI/CD integration

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Robot Framework Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.9'
    
    - name: Install dependencies
      run: make ci-setup
    
    - name: Run tests
      run: make ci-test
    
    - name: Upload test results
      uses: actions/upload-artifact@v2
      if: always()
      with:
        name: test-results
        path: results/
```

## Best Practices

### Test Organization

1. **Separate test types**: Keep API, GUI, and DB tests in separate directories
2. **Use tags**: Tag tests by type (smoke, regression, api, gui)
3. **Shared resources**: Put common keywords in `tests/resources/`
4. **Test data**: Store test data in `tests/data/` directory

### Keyword Design

1. **Single responsibility**: Each keyword should do one thing
2. **Meaningful names**: Use descriptive keyword names
3. **Documentation**: Document all custom keywords
4. **Error handling**: Include proper error handling and logging

### Maintenance

```bash
# Clean old results
make clean

# Update dependencies
pip install --upgrade -r requirements.txt

# Check for security vulnerabilities
pip audit
```

## Troubleshooting

### Common Issues

1. **Browser driver issues**: Ensure ChromeDriver/GeckoDriver is in PATH
2. **Import errors**: Check Python path and virtual environment
3. **Timeout issues**: Adjust timeout values in configuration
4. **SSL errors**: Configure SSL settings for API tests

### Debug Mode

Run tests with debug logging:
```bash
robot --loglevel DEBUG --outputdir results tests/
```

## Contributing

1. Follow Robot Framework naming conventions
2. Add tests for new features
3. Update documentation
4. Run linting before submitting PRs

## Resources

- [Robot Framework User Guide](https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html)
- [SeleniumLibrary Documentation](https://robotframework.org/SeleniumLibrary/)
- [RequestsLibrary Documentation](https://marketsquare.github.io/robotframework-requests/)
- [Robot Framework Best Practices](https://github.com/robotframework/HowToWriteGoodTestCases)
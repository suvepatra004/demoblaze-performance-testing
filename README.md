# Demoblaze Performance Testing

This project contains an Apache JMeter load test for the public Demoblaze website. It exercises a representative shopping journey: open the homepage, retrieve products, log in, view a random product, add it to the cart, and view the cart.

The test is intended for learning, capacity checks, and repeatable baseline measurements. It is not a functional test suite or a production monitoring solution.

## Test Scope

| Transaction    | HTTP operations                                                                          |
| -------------- | ---------------------------------------------------------------------------------------- |
| Open home      | `GET https://www.demoblaze.com/` and `GET https://api.demoblaze.com/entries`             |
| Login          | `POST https://api.demoblaze.com/login`                                                   |
| Browse product | `POST https://api.demoblaze.com/view` with a randomly selected product ID                |
| Add to cart    | `POST https://api.demoblaze.com/addtocart` and `POST https://api.demoblaze.com/viewcart` |

The main test plan contains the following load settings:

- Virtual users: `-Jthreads`
- Ramp-up time: `-Jrampup` seconds
- Test duration: `-Jduration` seconds
- Default load: 1 virtual user, 1-second ramp-up, 60-second scheduler
- Sample error policy: continue testing
- User pacing: 1-second constant delay plus up to 2 seconds random delay
- Repeated iterations: controlled by the configured duration

CSV users are shared by all threads and recycled when the data list is exhausted. The login response provides an authentication token that is reused for cart operations.

## Repository Structure

```text
demoblaze-performance-testing/
├── test-plans/
│   └── demoblaze-performance.jmx  # Parameterized, command-line-friendly test plan
├── test-data/
│   └── test-data.csv              # Test username and Base64 password values
├── demoblaze-performance.jmx      # Fixed-load development copy
├── results/
│   └── .gitkeep                   # JTL output directory
├── reports/
│   └── .gitkeep                   # HTML dashboard output directory
└── .gitignore                     # Excludes JMeter logs, JTL files, and reports
```

Use `test-plans/demoblaze-performance.jmx` for repeatable non-GUI runs. The root JMX file is a fixed-load copy with 3 users and 2 iterations.

## Prerequisites

- Apache JMeter 5.6.3 or a compatible JMeter 5.x release
- Java available on `PATH`
- Network access to `www.demoblaze.com` and `api.demoblaze.com`

Verify the tools:

```bash
java -version
jmeter -v
```

On macOS, JMeter can be installed with Homebrew:

```bash
brew install jmeter
```

## Initial Configuration

The test plan currently defines absolute paths for the CSV file. Before running from a different machine or directory, open the **CSV Data Set Config** in JMeter and set **Filename** to:

```text
/absolute/path/to/demoblaze-performance-testing/test-data/test-data.csv
```

To use a relative value, start JMeter from the repository root and set the filename to:

```text
test-data/test-data.csv
```

The CSV format is:

```csv
username,password
ratuser01,cmF0dXNlcjAx
ratuser02,cmF0dXNlcjAy
ratuser11,cmF0dXNlcjEx
```

The password column contains Base64-encoded test credentials. Existing accounts, or additional valid test accounts, may be required because Demoblaze is an external service. Do not place real credentials or secrets in this repository.

## Run the Test

Run from the repository root:

```bash
mkdir -p results reports

jmeter -n \
  -t test-plans/demoblaze-performance.jmx \
  -l results/demoblaze-results.jtl \
  -Jthreads=10 \
  -Jrampup=30 \
  -Jduration=300
```

Parameter meanings:

| Parameter  | Default | Example | Purpose                           |
| ---------- | ------: | ------: | --------------------------------- |
| `threads`  |     `1` |    `25` | Concurrent virtual users          |
| `rampup`   |     `1` |    `60` | Seconds used to start all users   |
| `duration` |    `60` |   `600` | Scheduled run duration in seconds |

For example, a 25-user, five-minute smoke or baseline run with a 60-second ramp is:

```bash
jmeter -n \
  -t test-plans/demoblaze-performance.jmx \
  -l results/baseline-25-users.jtl \
  -Jthreads=25 \
  -Jrampup=60 \
  -Jduration=300
```

## Generate an HTML Report

Generate a dashboard after an execution:

```bash
jmeter -g results/demoblaze-results.jtl \
  -o reports/demoblaze-dashboard
```

The dashboard includes throughput, response times, error counts, and time-series charts. Remove or replace an existing report directory before generating a new dashboard.

To run and generate the dashboard in one command:

```bash
jmeter -n \
  -t test-plans/demoblaze-performance.jmx \
  -l results/demoblaze-results.jtl \
  -e -o reports/demoblaze-dashboard \
  -Jthreads=10 \
  -Jrampup=30 \
  -Jduration=300
```

Generated `.jtl` files and dashboards are intentionally excluded by `.gitignore`.

## Test Data and Runtime Behavior

- `USERNAME` and `PASSWORD_B64` are read from the CSV Data Set.
- `PRODUCT_ID` is randomly selected from 1 through 9 for each thread iteration.
- `AUTH_TOKEN` is extracted from the login response body using `Auth_token: ...`.
- A UUID is generated for each cart item identifier.
- Cart requests use the extracted login token.
- The uniform random timer waits 1 to 3 seconds between virtual-user iterations.

## GUI Development

Open the test plan in JMeter GUI mode for editing or debugging:

```bash
jmeter -t test-plans/demoblaze-performance.jmx
```

The View Results Tree listener is disabled in the parameterized plan. Enable it only during small debugging runs because recording full response details adds overhead and can affect load measurements.

## Validation and Reporting Guidelines

Review these metrics before comparing runs:

- **Throughput:** completed requests or transactions per second
- **Response time:** average and percentile latency
- **Error percentage:** failed HTTP samples
- **Concurrency:** active threads during ramp and steady state
- **Transaction health:** results for each `TX01_*` through `TX04_*` transaction

Use the same JMeter version, host, network path, ramp-up, duration, and virtual-user count for valid comparisons. Establish and document environment-specific SLO thresholds before declaring a run a pass or fail.

The current plan does not assert HTTP status codes or response content, and it does not include formal pass/fail thresholds. Analysis should therefore confirm both JTL error rates and application behavior in the HTML dashboard.

## Known Considerations

- The tested application and external API availability are outside this repository's control.
- Demoblaze test accounts may be shared or changed without notice.
- Load results may vary with JMeter host resources, location, ISP routing, and third-party service health.
- `-Jduration` controls the scheduler; there is no separate command-line loop count.
- Response caching, browser rendering, JavaScript execution, and Think Time that occur in a real browser are not represented.
- The test plan uses the external Demoblaze API and should not be used for high-volume or production-like load without authorization.

---

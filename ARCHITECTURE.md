# Event Management System Architecture

## Overview

The Event Management System is a cloud-native fullstack application designed for deployment on Kubernetes. It follows a three-tier architecture with clear separation of concerns.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Users / Browsers                         │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ HTTP/HTTPS
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              NGINX Ingress Controller                       │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Routes:                                             │   │
│  │  - /        → Frontend Service                       │   │
│  │  - /back2   → Backend Service                        │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
            │                                    │
            │                                    │
            ▼                                    ▼
┌─────────────────────────┐        ┌─────────────────────────┐
│   Frontend Service      │        │   Backend Service       │
│   (ClusterIP/NodePort)  │        │   (ClusterIP/NodePort)  │
│   Port: 80              │        │   Port: 8080            │
└─────────────────────────┘        └─────────────────────────┘
            │                                    │
            │                                    │
            ▼                                    ▼
┌─────────────────────────┐        ┌─────────────────────────┐
│  Frontend Deployment    │        │  Backend Deployment     │
│  ┌───────────────────┐  │        │  ┌───────────────────┐  │
│  │   Pod (Replica 1) │  │        │  │   Pod (Replica 1) │  │
│  │   ┌─────────────┐ │  │        │  │   ┌─────────────┐ │  │
│  │   │  Nginx      │ │  │        │  │   │  Tomcat     │ │  │
│  │   │  + React    │ │  │        │  │   │  + Spring   │ │  │
│  │   │  App        │ │  │        │  │   │  Boot       │ │  │
│  │   └─────────────┘ │  │        │  │   └─────────────┘ │  │
│  └───────────────────┘  │        │  └───────────────────┘  │
│  ┌───────────────────┐  │        │  ┌───────────────────┐  │
│  │   Pod (Replica 2) │  │        │  │   Pod (Replica 2) │  │
│  └───────────────────┘  │        │  └───────────────────┘  │
│  HPA: 2-5 replicas      │        │  HPA: 2-5 replicas      │
└─────────────────────────┘        └─────────────────────────┘
                                                │
                                                │ JDBC
                                                ▼
                                   ┌─────────────────────────┐
                                   │   MySQL Service         │
                                   │   (ClusterIP)           │
                                   │   Port: 3306            │
                                   └─────────────────────────┘
                                                │
                                                ▼
                                   ┌─────────────────────────┐
                                   │  MySQL Deployment       │
                                   │  ┌───────────────────┐  │
                                   │  │   Pod (1 replica) │  │
                                   │  │   ┌─────────────┐ │  │
                                   │  │   │  MySQL 8.0  │ │  │
                                   │  │   └─────────────┘ │  │
                                   │  └───────────────────┘  │
                                   └─────────────────────────┘
                                                │
                                                │
                                                ▼
                                   ┌─────────────────────────┐
                                   │ Persistent Volume       │
                                   │ (5Gi Storage)           │
                                   └─────────────────────────┘
```

## Components

### 1. Frontend Layer

**Technology Stack:**
- React 19.1.1
- Vite 7.1.6 (Build tool)
- Material-UI (MUI) 7.3.2
- React Router DOM 7.9.1
- Axios for HTTP requests
- Nginx (Alpine) for serving

**Container Configuration:**
- Base Image: nginx:alpine
- Exposed Port: 80
- Build Process: Multi-stage Docker build
  - Stage 1: Node.js 18 for building React app
  - Stage 2: Nginx Alpine for serving static files

**Features:**
- Single Page Application (SPA)
- Client-side routing
- Responsive design with Material-UI
- Proxies backend requests through Nginx

**Nginx Configuration:**
- Serves React build files from `/usr/share/nginx/html`
- Proxies `/back2` requests to backend service
- Handles SPA routing with try_files directive

### 2. Backend Layer

**Technology Stack:**
- Spring Boot 3.4.3
- Java 17
- Spring Data JPA
- MySQL Connector
- Apache Tomcat 9.0

**Container Configuration:**
- Base Image: tomcat:9.0-jdk17-temurin
- Exposed Port: 8080
- Build Process: Multi-stage Docker build
  - Stage 1: Maven 3.9.6 with Java 17 for building
  - Stage 2: Tomcat 9.0 for runtime

**Features:**
- RESTful API endpoints
- JPA/Hibernate for ORM
- MySQL database integration
- Deployed as WAR file at `/back2` context path

**Database Configuration:**
- Database: `event`
- Username: `root`
- Password: `root` (configurable)
- Connection pool managed by Spring Boot
- Auto DDL update enabled

### 3. Database Layer

**Technology:**
- MySQL 8.0

**Configuration:**
- Root Password: `root`
- Database Name: `event`
- Port: 3306
- Storage: 5Gi Persistent Volume

**Features:**
- Persistent storage using PVC
- Readiness probe for health checking
- Automatic database initialization
- Single replica (stateful)

### 4. Kubernetes Resources

#### Deployments

**Frontend Deployment:**
- Replicas: 2 (default)
- Labels: `app=frontend`
- Update Strategy: RollingUpdate
- Resources: Auto-scaled by HPA

**Backend Deployment:**
- Replicas: 2 (default)
- Labels: `app=backend`
- Init Container: Waits for MySQL to be ready
- Update Strategy: RollingUpdate
- Resources: Auto-scaled by HPA

**MySQL Deployment:**
- Replicas: 1 (stateful)
- Labels: `app=mysql`
- Volume: Mounts PVC for data persistence
- Readiness Probe: mysqladmin ping

#### Services

**Frontend Service:**
- Type: NodePort / ClusterIP
- Port: 80
- NodePort: 30081 (optional)
- Selector: `app=frontend`

**Backend Service:**
- Type: NodePort / ClusterIP
- Port: 8080
- NodePort: 30080 (optional)
- Selector: `app=backend`

**MySQL Service:**
- Type: ClusterIP
- Port: 3306
- Selector: `app=mysql`

#### Ingress

**Configuration:**
- Ingress Class: nginx
- Host: eventmanagement.local
- Paths:
  - `/` → Frontend Service (Port 80)
  - `/back2` → Backend Service (Port 8080)

#### Horizontal Pod Autoscaler (HPA)

**Frontend HPA:**
- Min Replicas: 2
- Max Replicas: 5
- Target CPU: 60%

**Backend HPA:**
- Min Replicas: 2
- Max Replicas: 5
- Target CPU: 60%

#### Persistent Volume Claim

**MySQL PVC:**
- Access Mode: ReadWriteOnce
- Storage: 5Gi
- Storage Class: Default

## Data Flow

### 1. User Request Flow

```
User Browser
    ↓
    → HTTP Request to eventmanagement.local
    ↓
NGINX Ingress Controller
    ↓
    → Route based on path
    ↓
    ├─ Path: /          → Frontend Service → Frontend Pod (Nginx)
    │                                           ↓
    │                                      Serve React App
    │
    └─ Path: /back2     → Backend Service → Backend Pod (Tomcat)
                                               ↓
                                          Spring Boot Application
                                               ↓
                                          MySQL Database
```

### 2. Backend to Database Flow

```
Backend Pod
    ↓
Spring Boot Application
    ↓
JDBC Connection (jdbc:mysql://mysql:3306/event)
    ↓
MySQL Service (ClusterIP)
    ↓
MySQL Pod
    ↓
Persistent Volume
```

## Scalability Features

### Horizontal Pod Autoscaling

The system automatically scales based on CPU utilization:

1. **Metric Server**: Collects CPU/Memory metrics from pods
2. **HPA Controller**: Monitors metrics and adjusts replica count
3. **Scaling Decisions**:
   - Scale up: When CPU > 60% for sustained period
   - Scale down: When CPU < 60% and not at minimum replicas

### Load Balancing

- **Ingress Level**: NGINX Ingress distributes traffic across frontend pods
- **Service Level**: Kubernetes Services load balance across backend pods
- **Database**: Single instance (MySQL doesn't auto-scale)

## High Availability Features

### Replica Management

- **Frontend**: Multiple replicas ensure availability during pod failures
- **Backend**: Multiple replicas with init containers ensure safe startup
- **Database**: Single replica with persistent storage for data durability

### Health Checks

- **MySQL**: Readiness probe using mysqladmin ping
- **Backend**: Init container waits for MySQL before starting
- **Frontend**: Nginx handles health checks implicitly

### Data Persistence

- **PVC**: Ensures data survives pod restarts
- **Access Mode**: ReadWriteOnce for MySQL
- **Backup**: Manual backup strategy needed for production

## Security Considerations

### Network Policies

- All services use ClusterIP for internal communication
- External access only through Ingress or NodePort
- MySQL not exposed externally

### Secrets Management

- Database credentials stored in Helm values
- Should use Kubernetes Secrets in production
- Environment variables for sensitive data

### Image Security

- Use official base images (nginx:alpine, mysql:8.0, tomcat:9.0)
- Multi-stage builds reduce attack surface
- Regular image updates recommended

## Monitoring and Observability

### Logging

- **Frontend**: Nginx access/error logs
- **Backend**: Spring Boot logs (stdout)
- **Database**: MySQL logs

### Metrics

- **HPA**: CPU utilization metrics
- **Kubernetes**: Pod/Node metrics
- **Application**: Custom metrics via Spring Boot Actuator (if enabled)

## Deployment Strategies

### Rolling Update

- Default strategy for Deployments
- Zero-downtime updates
- Gradual replacement of old pods

### Blue-Green Deployment

- Deploy new version alongside old
- Switch traffic via Service selector
- Quick rollback if needed

### Canary Deployment

- Route percentage of traffic to new version
- Monitor metrics before full rollout
- Use Ingress annotations for traffic splitting

## Future Enhancements

1. **Microservices**: Split backend into smaller services
2. **API Gateway**: Add dedicated API gateway
3. **Service Mesh**: Implement Istio/Linkerd for advanced traffic management
4. **Monitoring**: Add Prometheus/Grafana stack
5. **Logging**: Implement ELK/EFK stack
6. **CI/CD**: Integrate with Jenkins/GitLab CI
7. **Database**: Add read replicas for MySQL
8. **Caching**: Implement Redis for session/data caching
9. **Message Queue**: Add RabbitMQ/Kafka for async processing
10. **Security**: Implement OAuth2/OIDC authentication

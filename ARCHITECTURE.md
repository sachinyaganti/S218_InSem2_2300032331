# Architecture Documentation

## Overview

The Event Management System is a cloud-native fullstack application designed for high availability, scalability, and automated deployment on Kubernetes. It follows microservices architecture principles and leverages Kubernetes native features for orchestration.

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                       │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                  Ingress Controller                   │   │
│  │                    (NGINX)                            │   │
│  └──────────────┬──────────────────┬────────────────────┘   │
│                 │                  │                          │
│                 ▼                  ▼                          │
│  ┌──────────────────────┐  ┌──────────────────────┐         │
│  │   Frontend Service   │  │   Backend Service    │         │
│  │    (ClusterIP/NP)    │  │    (ClusterIP/NP)    │         │
│  └──────────┬───────────┘  └──────────┬───────────┘         │
│             │                          │                      │
│             ▼                          ▼                      │
│  ┌──────────────────────┐  ┌──────────────────────┐         │
│  │  Frontend Pods (2-5) │  │  Backend Pods (2-5)  │         │
│  │  ┌────────────────┐  │  │  ┌────────────────┐ │         │
│  │  │ Nginx + React  │  │  │  │ Tomcat + Spring│ │         │
│  │  │     (Vite)     │  │  │  │      Boot      │ │         │
│  │  └────────────────┘  │  │  └────────────────┘ │         │
│  │  Auto-scaling (HPA)  │  │  Auto-scaling (HPA)  │         │
│  └──────────────────────┘  └──────────┬───────────┘         │
│                                        │                      │
│                                        ▼                      │
│                             ┌──────────────────────┐         │
│                             │   MySQL Service      │         │
│                             │     (ClusterIP)      │         │
│                             └──────────┬───────────┘         │
│                                        │                      │
│                                        ▼                      │
│                             ┌──────────────────────┐         │
│                             │     MySQL Pod        │         │
│                             │  ┌────────────────┐ │         │
│                             │  │   MySQL 8.0    │ │         │
│                             │  └────────────────┘ │         │
│                             │         │            │         │
│                             │         ▼            │         │
│                             │  ┌────────────────┐ │         │
│                             │  │  Persistent    │ │         │
│                             │  │    Volume      │ │         │
│                             │  └────────────────┘ │         │
│                             └──────────────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### Frontend Layer

**Technology Stack:**
- React (v19.1.1) - UI Framework
- Vite (v7.1.6) - Build Tool
- Material-UI (v7.3.2) - Component Library
- Nginx (Alpine) - Web Server

**Responsibilities:**
- Serve static assets
- Handle user interactions
- Communicate with backend APIs
- Responsive UI/UX

**Scaling:**
- Horizontal Pod Autoscaler configured
- Scales from 2 to 5 replicas based on CPU (60% threshold)
- Each pod has resource limits: 512Mi memory, 200m CPU

### Backend Layer

**Technology Stack:**
- Spring Boot 3.4.3 - Application Framework
- Java 17 - Runtime
- Spring Data JPA - ORM
- MySQL Connector - Database Driver
- Apache Tomcat 9.0 - Application Server

**Responsibilities:**
- Business logic processing
- RESTful API endpoints
- Database operations
- Data validation and transformation

**Scaling:**
- Horizontal Pod Autoscaler configured
- Scales from 2 to 5 replicas based on CPU (60% threshold)
- Each pod has resource limits: 1Gi memory, 500m CPU
- Init container ensures MySQL is ready before startup

### Database Layer

**Technology:**
- MySQL 8.0

**Responsibilities:**
- Persistent data storage
- Transaction management
- Data integrity and consistency

**High Availability:**
- Persistent Volume for data durability
- Readiness probe to ensure availability
- 5Gi storage allocation

## Networking

### Service Discovery

All services use Kubernetes DNS for service discovery:
- `mysql:3306` - MySQL database
- `backend:8080` - Backend API
- `frontend:80` - Frontend application

### Ingress Configuration

- **Host:** eventmanagement.local
- **Frontend Path:** `/` → frontend:80
- **Backend Path:** `/api` → backend:8080
- **Ingress Class:** nginx

### Port Mapping

| Component | Container Port | Service Port | NodePort (Optional) |
|-----------|---------------|--------------|---------------------|
| Frontend  | 80            | 80           | 30081              |
| Backend   | 8080          | 8080         | 30080              |
| MySQL     | 3306          | 3306         | -                  |

## Data Flow

### User Request Flow

1. User accesses `http://eventmanagement.local`
2. DNS resolves to Ingress Controller
3. Ingress Controller routes to Frontend Service
4. Frontend Service load-balances to Frontend Pods
5. Frontend serves static assets
6. User interactions trigger API calls to `/api`
7. Ingress routes `/api` to Backend Service
8. Backend Service load-balances to Backend Pods
9. Backend processes request and queries MySQL
10. Response flows back through the chain

### Database Connection Flow

1. Backend pods connect to MySQL via service name: `jdbc:mysql://mysql:3306/eventmanagement`
2. Connection pooling managed by Spring Boot
3. Hibernate ORM handles database operations
4. Database schema auto-updated on deployment

## Scalability Features

### Horizontal Pod Autoscaling (HPA)

**Frontend HPA:**
```yaml
minReplicas: 2
maxReplicas: 5
targetCPUUtilizationPercentage: 60
```

**Backend HPA:**
```yaml
minReplicas: 2
maxReplicas: 5
targetCPUUtilizationPercentage: 60
```

### Resource Management

**Frontend Pods:**
- Requests: 256Mi memory, 100m CPU
- Limits: 512Mi memory, 200m CPU

**Backend Pods:**
- Requests: 512Mi memory, 250m CPU
- Limits: 1Gi memory, 500m CPU

## High Availability

### Pod Distribution

- Multiple replicas for frontend and backend
- Kubernetes scheduler distributes across nodes
- Anti-affinity rules can be added for better distribution

### Health Checks

**MySQL:**
- Readiness probe: mysqladmin ping
- Initial delay: 15s
- Period: 5s

**Backend:**
- Init container waits for MySQL availability
- Uses `nc` (netcat) to check MySQL port 3306

### Data Persistence

- PersistentVolumeClaim for MySQL data
- Storage: 5Gi (configurable)
- Access Mode: ReadWriteOnce
- Data survives pod restarts

## Security Considerations

### Network Policies (Future Enhancement)

- Restrict pod-to-pod communication
- Allow only necessary ingress/egress

### Secrets Management (Future Enhancement)

- Use Kubernetes Secrets for passwords
- External secret management (Vault, AWS Secrets Manager)

### RBAC (Future Enhancement)

- Service accounts for pods
- Role-based access control

## Deployment Strategy

### Rolling Updates

- Default deployment strategy
- Zero-downtime deployments
- Gradual rollout of new versions

### Rollback Capability

```bash
helm rollback event-management <revision>
```

## Monitoring and Observability (Future Enhancement)

### Metrics
- Prometheus for metrics collection
- Grafana for visualization
- HPA metrics from metrics-server

### Logging
- Centralized logging with ELK/EFK stack
- Application logs
- Access logs

### Tracing
- Distributed tracing with Jaeger/Zipkin
- Request flow tracking

## Disaster Recovery

### Backup Strategy

1. **Database Backups:**
   - Regular MySQL dumps
   - PV snapshots
   - Off-cluster backup storage

2. **Configuration Backups:**
   - Helm chart versioning
   - Values.yaml in version control

### Recovery Procedures

1. **Application Recovery:**
   ```bash
   helm install event-management ./helm-chart
   ```

2. **Database Recovery:**
   - Restore from backup
   - Re-attach PV
   - Verify data integrity

## Performance Optimization

### Frontend
- Static asset caching via Nginx
- Gzip compression
- CDN integration (future)

### Backend
- Connection pooling
- Query optimization
- Caching layer (Redis - future)

### Database
- Indexed columns
- Query optimization
- Read replicas (future)

## Technology Versions

| Component | Version |
|-----------|---------|
| Kubernetes | 1.19+ |
| Helm | 3.x |
| React | 19.1.1 |
| Vite | 7.1.6 |
| Spring Boot | 3.4.3 |
| Java | 17 |
| MySQL | 8.0 |
| Nginx | Alpine |
| Tomcat | 9.0 |

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [React Documentation](https://react.dev/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)

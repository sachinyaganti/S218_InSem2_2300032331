# Deployment Validation Checklist

This checklist helps verify that the Event Management System deployment is successful.

## Pre-Deployment Checklist

### Prerequisites
- [ ] Kubernetes cluster is running and accessible
- [ ] kubectl is configured and can access the cluster
- [ ] Helm 3.x is installed
- [ ] Docker is installed (for building images)
- [ ] NGINX Ingress Controller is installed (or will be installed during deployment)

### Image Build Verification
- [ ] Backend Docker image builds successfully
  ```bash
  docker build -t event-management-backend:v1 ./backend
  ```
- [ ] Frontend Docker image builds successfully
  ```bash
  docker build -t event-management-frontend:v1 ./frontend
  ```
- [ ] Images are tagged correctly
  ```bash
  docker images | grep event-management
  ```

### Configuration Verification
- [ ] Helm values.yaml is configured correctly
- [ ] Image names match built images or registry images
- [ ] Database credentials are set (change default password in production)
- [ ] Ingress host is configured appropriately
- [ ] NodePort values don't conflict with existing services

## Deployment Checklist

### Helm Deployment
- [ ] Helm chart validates without errors
  ```bash
  helm lint helm-chart
  ```
- [ ] Helm install/upgrade completes successfully
  ```bash
  helm install event-management ./helm-chart
  ```
- [ ] Check Helm release status
  ```bash
  helm list
  helm status event-management
  ```

### Resource Verification

#### Deployments
- [ ] MySQL deployment is created
  ```bash
  kubectl get deployment mysql
  ```
- [ ] Backend deployment is created
  ```bash
  kubectl get deployment backend
  ```
- [ ] Frontend deployment is created
  ```bash
  kubectl get deployment frontend
  ```

#### Pods
- [ ] All pods are in Running state
  ```bash
  kubectl get pods
  ```
- [ ] MySQL pod is ready (1/1)
- [ ] Backend pods are ready (2/2 or more)
- [ ] Frontend pods are ready (2/2 or more)
- [ ] No pods are in CrashLoopBackOff or Error state

#### Services
- [ ] MySQL service is created (ClusterIP)
  ```bash
  kubectl get svc mysql
  ```
- [ ] Backend service is created (NodePort)
  ```bash
  kubectl get svc backend
  ```
- [ ] Frontend service is created (NodePort)
  ```bash
  kubectl get svc frontend
  ```
- [ ] Services have endpoints
  ```bash
  kubectl get endpoints
  ```

#### Storage
- [ ] PVC is created for MySQL
  ```bash
  kubectl get pvc mysql-pvc
  ```
- [ ] PVC is bound to a PV
  ```bash
  kubectl describe pvc mysql-pvc
  ```

#### Ingress
- [ ] Ingress resource is created
  ```bash
  kubectl get ingress
  ```
- [ ] Ingress has an address assigned
  ```bash
  kubectl describe ingress event-management-ingress
  ```

#### HPA
- [ ] Backend HPA is created
  ```bash
  kubectl get hpa backend-hpa
  ```
- [ ] Frontend HPA is created
  ```bash
  kubectl get hpa frontend-hpa
  ```
- [ ] HPA shows current/target metrics

## Post-Deployment Verification

### Pod Health
- [ ] MySQL pod logs show successful startup
  ```bash
  kubectl logs -l app=mysql
  ```
- [ ] Backend pod logs show successful startup
  ```bash
  kubectl logs -l app=backend
  ```
- [ ] Frontend pod logs show nginx started
  ```bash
  kubectl logs -l app=frontend
  ```

### Database Connectivity
- [ ] Backend can connect to MySQL
  ```bash
  kubectl logs -l app=backend | grep -i mysql
  ```
- [ ] No database connection errors in backend logs
- [ ] Database tables are created (check backend logs for Hibernate DDL)

### Network Connectivity

#### Internal Communication
- [ ] Frontend can reach backend service
  ```bash
  kubectl exec -it <frontend-pod> -- wget -O- http://backend:8080
  ```
- [ ] Backend can reach MySQL service
  ```bash
  kubectl exec -it <backend-pod> -- nc -zv mysql 3306
  ```

#### External Access via NodePort
- [ ] Frontend is accessible via NodePort
  ```bash
  curl http://<node-ip>:30081
  ```
- [ ] Backend is accessible via NodePort
  ```bash
  curl http://<node-ip>:30080/back2
  ```

#### External Access via Ingress
- [ ] Get Ingress IP/hostname
  ```bash
  kubectl get ingress event-management-ingress
  ```
- [ ] Configure /etc/hosts or DNS
- [ ] Frontend is accessible via Ingress
  ```bash
  curl http://eventmanagement.local
  ```
- [ ] Backend is accessible via Ingress
  ```bash
  curl http://eventmanagement.local/back2
  ```

### Application Functionality

#### Frontend Tests
- [ ] Frontend loads in browser
- [ ] Static assets load correctly
- [ ] No JavaScript errors in browser console
- [ ] Navigation works (routing)

#### Backend Tests
- [ ] Backend API responds
  ```bash
  curl http://<ingress-host>/back2/test
  ```
- [ ] API endpoints are accessible
- [ ] No 500 errors in responses

#### Integration Tests
- [ ] Frontend can call backend APIs
- [ ] Data is persisted in MySQL
- [ ] User registration works
- [ ] Login functionality works
- [ ] CRUD operations work

### Scaling Tests

#### HPA Verification
- [ ] Check metrics server is running
  ```bash
  kubectl get deployment metrics-server -n kube-system
  ```
- [ ] HPA shows current CPU usage
  ```bash
  kubectl get hpa
  ```
- [ ] Generate load to test auto-scaling
  ```bash
  kubectl run -it load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://backend:8080; done"
  ```
- [ ] Observe HPA scaling up
  ```bash
  kubectl get hpa -w
  ```
- [ ] Stop load and observe scaling down

#### Manual Scaling
- [ ] Scale backend manually
  ```bash
  kubectl scale deployment backend --replicas=5
  ```
- [ ] Verify all replicas are running
- [ ] Service distributes traffic across all replicas
- [ ] Scale back to original
  ```bash
  kubectl scale deployment backend --replicas=2
  ```

### Persistence Tests
- [ ] Write data to the application
- [ ] Delete MySQL pod
  ```bash
  kubectl delete pod -l app=mysql
  ```
- [ ] Wait for new MySQL pod to start
- [ ] Verify data is still present
- [ ] Confirms PVC is working correctly

### Update and Rollback Tests
- [ ] Perform Helm upgrade
  ```bash
  helm upgrade event-management ./helm-chart
  ```
- [ ] Verify rolling update
  ```bash
  kubectl rollout status deployment/backend
  kubectl rollout status deployment/frontend
  ```
- [ ] Test rollback
  ```bash
  helm rollback event-management
  ```
- [ ] Verify rollback successful

## Monitoring Checklist

### Resource Usage
- [ ] Check pod resource usage
  ```bash
  kubectl top pods
  ```
- [ ] Check node resource usage
  ```bash
  kubectl top nodes
  ```
- [ ] Verify resources are within limits

### Logs Collection
- [ ] Backend logs are accessible
- [ ] Frontend logs are accessible
- [ ] MySQL logs are accessible
- [ ] No critical errors in logs

### Events
- [ ] Check cluster events
  ```bash
  kubectl get events --sort-by='.lastTimestamp'
  ```
- [ ] No warning or error events

## Security Checklist

### Network Security
- [ ] MySQL is not exposed externally (ClusterIP only)
- [ ] Services use appropriate service types
- [ ] Ingress uses appropriate annotations

### Configuration Security
- [ ] Database credentials are secured (use Secrets in production)
- [ ] No hardcoded credentials in code
- [ ] Environment variables are used appropriately

## Production Readiness Checklist

### High Availability
- [ ] Multiple replicas for frontend (2+)
- [ ] Multiple replicas for backend (2+)
- [ ] HPA is configured and working
- [ ] Health probes are configured

### Data Persistence
- [ ] PVC is configured for MySQL
- [ ] Backup strategy is defined
- [ ] Restore procedure is tested

### Monitoring and Logging
- [ ] Logging solution is in place (optional)
- [ ] Monitoring solution is in place (optional)
- [ ] Alerts are configured (optional)

### Documentation
- [ ] README.md is complete
- [ ] ARCHITECTURE.md describes the system
- [ ] DEPLOYMENT.md provides deployment steps
- [ ] SUMMARY.md provides overview

### Security Hardening (Production)
- [ ] Use Kubernetes Secrets for sensitive data
- [ ] Enable TLS/SSL on Ingress
- [ ] Implement Network Policies
- [ ] Enable RBAC
- [ ] Use Pod Security Policies
- [ ] Regular security scans of images
- [ ] Change default passwords

## Troubleshooting Reference

### Common Issues

#### Pods Not Starting
- Check: `kubectl describe pod <pod-name>`
- Check: `kubectl logs <pod-name>`
- Common causes: Image pull errors, resource constraints, configuration errors

#### Database Connection Errors
- Check MySQL pod status
- Check MySQL service endpoints
- Verify backend environment variables
- Check init container logs

#### Ingress Not Working
- Verify Ingress Controller is running
- Check Ingress resource configuration
- Verify DNS/hosts configuration
- Check Ingress Controller logs

#### HPA Not Scaling
- Verify metrics server is installed
- Check HPA configuration
- Generate sufficient load
- Check resource requests are set

## Sign-off

### Deployment Sign-off
- [ ] All critical checks passed
- [ ] Application is accessible
- [ ] Data persistence verified
- [ ] Scaling tested
- [ ] Documentation complete

**Deployed by:** _____________  
**Date:** _____________  
**Environment:** _____________  
**Version:** _____________  

### Notes
_____________________________________________
_____________________________________________
_____________________________________________

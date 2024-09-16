apiVersion: apps/v1
kind: Deployment
metadata:
  name: zk-evm-worker
  labels:
    release: {{ .Release.Name }}
    app: zk-evm
    component: worker
spec:
  # The number of replicas should be set to one as it is managed by the HPA.
  replicas: {{ if .Values.worker.autoscaler.enabled }}1{{- else }}{{ .Values.worker.workerCount }}{{- end }}
  selector:
    matchLabels:
      app: zk-evm
      component: worker
  template:
    metadata:
      labels:
        app: zk-evm
        component: worker
    spec:
      initContainers:
      - name: circuits-checker
        image: busybox
        command: ["/bin/sh", "-c"]
        args:
        - |
          while [ ! -f /circuits/.initialized ]; do
            echo "Waiting for circuits initialization to complete..."
            sleep 10
          done
          echo "Circuits initialization complete"
        volumeMounts:
        - name: circuits
          mountPath: /circuits

      containers:
      - name: worker
        image: {{ .Values.worker.image }}
        command: ["worker"]
        args:
        {{- with .Values.worker.flags }}
        {{- range . }}
        - {{ . }}
        {{- end }}
        {{- end }}
        envFrom:
        - configMapRef:
            name: zk-evm-worker-cm
        volumeMounts:
        - name: circuits
          mountPath: /circuits
        # TODO: Remove this after testing.
        securityContext:
          runAsUser: 0
        resources:
          requests:
            memory: {{ .Values.worker.resources.requests.memory }}
            cpu: {{ .Values.worker.resources.requests.cpu }}
          limits:
            memory: {{ .Values.worker.resources.limits.memory }}
            cpu: {{ .Values.worker.resources.limits.cpu }}
      volumes:
      - name: circuits
        persistentVolumeClaim:
          claimName: zk-evm-worker-circuits-pvc
      nodeSelector:
      {{ toYaml .Values.worker.nodeSelector | indent 8 }}
      tolerations:
      {{ toYaml .Values.worker.tolerations | indent 8 }}

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: zk-evm-worker-cm
data:
  AMQP_URI: {{ printf "amqp://%s:%s@rabbitmq-cluster.%s.svc.cluster.local:5672" .Values.rabbitmq.cluster.credentials.username .Values.rabbitmq.cluster.credentials.password .Release.Namespace }}
  {{- range $key, $value := .Values.worker.env }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}

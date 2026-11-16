# Отчёт о проверках

## 1. Уровень 4–6: SQLite, один контейнер

```
$ docker run -d --name counter -p 8080:8000 -v counter-data:/data counter-app
$ docker logs counter
2026-11-16 12:05:30,938 listening port=8000 storage=sqlite
2026-11-16 12:05:40,007 http 192.168.65.1 "GET / HTTP/1.1" 200 -
2026-11-16 12:05:46,602 http 192.168.65.1 "GET / HTTP/1.1" 200 -
2026-11-16 12:05:49,804 http 192.168.65.1 "GET / HTTP/1.1" 200 -
2026-11-16 12:41:32,031 http 192.168.65.1 "GET / HTTP/1.1" 200 -
2026-11-16 12:42:57,396 http 192.168.65.1 "POST /increment HTTP/1.1" 200 -
2026-11-16 12:43:00,881 http 192.168.65.1 "POST /increment HTTP/1.1" 200 -
2026-11-16 12:43:53,177 http 192.168.65.1 "GET /readyz HTTP/1.1" 200 -
2026-11-16 12:44:11,118 http 192.168.65.1 "GET /healthz HTTP/1.1" 200 -
2026-11-16 12:45:36,989 http 192.168.65.1 "GET / HTTP/1.1" 200 -
```

## 2. Compose + Redis: первый запуск с пустым хранилищем

```
$ docker compose up -d
 ✔ Image redis:7.4-alpine   Pulled
 ✔ Network app_default      Created
 ✔ Volume app_redis-data    Created
 ✔ Container app-redis-1    Healthy
 ✔ Container app-app-1      Started

$ curl -fsS -X POST http://127.0.0.1:8080/increment
{"greeting": "Hello, Docker!", "count": 1, "hostname": "167c1742260c", "storage": "redis"}
$ curl -fsS -X POST http://127.0.0.1:8080/increment
{"greeting": "Hello, Docker!", "count": 2, "hostname": "167c1742260c", "storage": "redis"}
$ curl -fsS -X POST http://127.0.0.1:8080/increment
{"greeting": "Hello, Docker!", "count": 3, "hostname": "167c1742260c", "storage": "redis"}
```

## 3. Счётчик сохраняется после `down` и повторного `up -d`

```
$ docker compose down
 ✔ Container app-app-1    Removed
 ✔ Container app-redis-1  Removed
 ✔ Network app_default    Removed

$ docker compose ps -a
NAME   IMAGE   COMMAND   SERVICE   CREATED   STATUS   PORTS

$ docker volume ls
DRIVER    VOLUME NAME
local     app_redis-data
local     counter-data

$ docker compose up -d
 ✔ Network app_default    Created
 ✔ Container app-redis-1  Healthy
 ✔ Container app-app-1    Started

$ curl -sS -w '  HTTP %{http_code}\n' http://127.0.0.1:8080/
{"greeting": "Hello, Docker!", "count": 3, "hostname": "6a1454473f0b", "storage": "redis"}  HTTP 200
```

## 4. Пересоздание контейнера приложения при работающем Redis

```
$ docker compose up -d --build
 ✔ Image counter-app       Built
 ✔ Container app-redis-1   Healthy
 ✔ Container app-app-1     Started

$ docker compose ps
NAME          IMAGE              STATUS                    PORTS
app-app-1     counter-app        Up 8 seconds (healthy)    0.0.0.0:8080->8000/tcp, [::]:8080->8000/tcp
app-redis-1   redis:7.4-alpine   Up 30 minutes (healthy)   6379/tcp

$ curl -sS -w '  HTTP %{http_code}\n' -X POST http://127.0.0.1:8080/increment
{"greeting": "Hello, Docker!", "count": 4, "hostname": "18ed2ae1c445", "storage": "redis"}  HTTP 200
$ curl -sS -w '  HTTP %{http_code}\n' -X POST http://127.0.0.1:8080/increment
{"greeting": "Hello, Docker!", "count": 5, "hostname": "18ed2ae1c445", "storage": "redis"}  HTTP 200
$ curl -sS -w '  HTTP %{http_code}\n' -X POST http://127.0.0.1:8080/increment
{"greeting": "Hello, Docker!", "count": 6, "hostname": "18ed2ae1c445", "storage": "redis"}  HTTP 200
```

## 5. Повторная проверка

```
$ docker compose down
 ✔ Container app-app-1    Removed
 ✔ Container app-redis-1  Removed
 ✔ Network app_default    Removed

$ docker compose up -d
 ✔ Network app_default    Created
 ✔ Container app-redis-1  Healthy
 ✔ Container app-app-1    Started

$ curl -sS -w '  HTTP %{http_code}\n' http://127.0.0.1:8080/
{"greeting": "Hello, Docker!", "count": 6, "hostname": "d38b184c40b6", "storage": "redis"}  HTTP 200
```

## 6. Redis остановлен — приложение продолжает работать

```
$ docker compose stop redis
 ✔ Container app-redis-1  Stopped

$ curl -sS -w '  HTTP %{http_code}\n' http://127.0.0.1:8080/healthz
{"status": "alive"}  HTTP 200
$ curl -sS -w '  HTTP %{http_code}\n' http://127.0.0.1:8080/readyz
{"error": "storage_unavailable"}  HTTP 503
$ curl -sS -w '  HTTP %{http_code}\n' -X POST http://127.0.0.1:8080/increment
{"error": "storage_unavailable"}  HTTP 503

$ docker compose ps
NAME        IMAGE         STATUS                        PORTS
app-app-1   counter-app   Up About a minute (healthy)   0.0.0.0:8080->8000/tcp, [::]:8080->8000/tcp
```

## 7. Redis снова запущен — без перезапуска приложения

```
$ docker compose start redis
 ✔ Container app-redis-1  Started

$ docker compose ps
NAME          IMAGE              STATUS                   PORTS
app-app-1     counter-app        Up 2 minutes (healthy)   0.0.0.0:8080->8000/tcp, [::]:8080->8000/tcp
app-redis-1   redis:7.4-alpine   Up 6 seconds (healthy)   6379/tcp

$ curl -sS -w '  HTTP %{http_code}\n' http://127.0.0.1:8080/
{"greeting": "Hello, Docker!", "count": 6, "hostname": "d38b184c40b6", "storage": "redis"}  HTTP 200
$ curl -sS -w '  HTTP %{http_code}\n' -X POST http://127.0.0.1:8080/increment
{"greeting": "Hello, Docker!", "count": 7, "hostname": "d38b184c40b6", "storage": "redis"}  HTTP 200
```

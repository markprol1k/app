## Приложение

Учебный HTTP-сервис со счётчиком. 

| Запрос | Результат |
| --- | --- |
| `GET /` | JSON с `greeting`, `count`, `hostname`, `storage`; счётчик не меняется |
| `POST /increment` | Увеличить счётчик на 1, вернуть тот же JSON; тело не требуется |
| `GET /healthz` | HTTP 200, если HTTP-сервер работает |
| `GET /readyz` | HTTP 200 при доступном хранилище, иначе 503 |

При недоступности Redis `GET /` и `POST /increment` тоже возвращают 503.
Приложение не сбрасывает данные и не переключается на SQLite при сбое Redis.
После восстановления Redis следующий запрос снова может выполниться.
Для проверки JSON открывайте адрес в браузере или используйте `curl`.

## Настройки

| Переменная | По умолчанию | Значение |
| --- | --- | --- |
| `PORT` | `8000` | Порт внутри контейнера; приложение слушает `0.0.0.0` |
| `GREETING` | `Hello, Docker!` | Текст поля `greeting` |
| `STORAGE` | `sqlite` | `sqlite` для 4–6 баллов; `redis` для 8–10 |
| `DATA_FILE` | `/data/counter.db` | Путь SQLite, используется только в режиме sqlite |
| `REDIS_URL` | `redis://redis:6379/0` | Адрес Redis, используется только в режиме redis |

SQLite — база в одном файле; при удалении контейнера без volume файл пропадёт.
В режиме Redis приложение не пишет локальные данные; Redis хранит ключ
`docker-hw:counter`. Перенос счётчика из SQLite в Redis не нужен.

Для образа подойдёт официальный `python:3.13-slim`, для хранилища —
`redis:7.4-alpine`. Теги задают семейство версии, но могут обновляться;
для неизменного содержимого существует привязка по digest. Digest в ДЗ
не обязателен. Пакет redis — клиент, сам сервер Redis он не устанавливает.

## Проверка после запуска контейнера

```sh
curl -fsS http://127.0.0.1:8080/
curl -fsS -X POST http://127.0.0.1:8080/increment
curl -fsS http://127.0.0.1:8080/readyz
```

Первый POST в новом хранилище возвращает `count: 1`. GET счётчик не
увеличивает. В браузере удобнее смотреть GET, для POST используйте curl.

## Запуск

### SQLite (уровень 4–6)

```sh
docker build -t counter-app .
docker run -d --name counter -p 8080:8000 -v counter-data:/data counter-app
```

Приветствие задаётся через `-e GREETING='Привет, Docker!'`.

Остановка: `docker rm -f counter`.

### Docker Compose с Redis (уровень 6–8)

```sh
cp .env.example .env
docker compose up -d --build
docker compose ps
```

В `compose.yaml` два сервиса:

- `app` собирается из `Dockerfile` и работает с `STORAGE=redis`.
- `redis` использует образ `redis:7.4-alpine`, хранит данные в volume `redis-data`. `app` запускается после того, как Redis готов.

### Проверка

```sh
curl -sS -X POST http://127.0.0.1:8080/increment
docker compose down
docker compose up -d
curl -sS http://127.0.0.1:8080/

docker compose stop redis
curl -sS http://127.0.0.1:8080/healthz
curl -sS http://127.0.0.1:8080/readyz
curl -sS -X POST http://127.0.0.1:8080/increment

docker compose start redis
curl -sS http://127.0.0.1:8080/
curl -sS -X POST http://127.0.0.1:8080/increment
```

### Остановка

```sh
docker compose down
docker compose down -v
```

`down -v` удаляет и данные.

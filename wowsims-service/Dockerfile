FROM golang:1.25.4-bookworm AS builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates git protobuf-compiler python3 \
    && rm -rf /var/lib/apt/lists/* \
    && go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.36.10

ARG CLASSIC_COMMIT=7779ebbf79dc7f1341e6ab939b28a3402c9a730a
ARG TBC_COMMIT=a4768c9d7ed51f4e49b8e90425f68ab47bde0cbc
ARG WOTLK_COMMIT=563e4a08cb15729f1fdcbcf68e6d68224553bfef

ENV GOTOOLCHAIN=auto
COPY harvest_presets.py /tools/harvest_presets.py
COPY model-support.json /tools/model-support.json
WORKDIR /src

RUN git init classic \
    && git -C classic remote add origin https://github.com/wowsims/classic.git \
    && git -C classic fetch --depth 1 origin "${CLASSIC_COMMIT}" \
    && git -C classic checkout --detach FETCH_HEAD \
    && cd classic \
    && protoc -I=./proto --go_out=./sim/core ./proto/*.proto \
    && CGO_ENABLED=0 go build --tags=with_db -trimpath -ldflags="-s -w" -o /out/wowsimcli-classic ./cmd/wowsimcli/cli_main.go
RUN python3 /tools/harvest_presets.py \
    --source /src/classic --era VANILLA --output /presets/VANILLA \
    --model-support /tools/model-support.json --commit "${CLASSIC_COMMIT}"

RUN git init tbc \
    && git -C tbc remote add origin https://github.com/wowsims/tbc-new.git \
    && git -C tbc fetch --depth 1 origin "${TBC_COMMIT}" \
    && git -C tbc checkout --detach FETCH_HEAD \
    && cd tbc \
    && protoc -I=./proto -I=/usr/include \
        --go_opt=Mgoogle/protobuf/descriptor.proto=google.golang.org/protobuf/types/descriptorpb \
        --go_out=./sim/core ./proto/*.proto \
    && CGO_ENABLED=0 go build --tags=with_db -trimpath -ldflags="-s -w" -o /out/wowsimcli-tbc ./cmd/wowsimcli/cli_main.go
RUN python3 /tools/harvest_presets.py \
    --source /src/tbc --era TBC --output /presets/TBC \
    --model-support /tools/model-support.json --commit "${TBC_COMMIT}"

RUN git init wotlk \
    && git -C wotlk remote add origin https://github.com/wowsims/wotlk.git \
    && git -C wotlk fetch --depth 1 origin "${WOTLK_COMMIT}" \
    && git -C wotlk checkout --detach FETCH_HEAD \
    && cd wotlk \
    && protoc -I=./proto --go_out=./sim/core ./proto/*.proto \
    && CGO_ENABLED=0 go build --tags=with_db -trimpath -ldflags="-s -w" -o /out/wowsimcli-wotlk ./cmd/wowsimcli/cli_main.go
RUN python3 /tools/harvest_presets.py \
    --source /src/wotlk --era WOTLK --output /presets/WOTLK \
    --model-support /tools/model-support.json --commit "${WOTLK_COMMIT}"

FROM python:3.12-slim

RUN useradd --system --uid 10001 --no-create-home --home-dir /nonexistent skrra

WORKDIR /app
COPY app.py /app/app.py
COPY sources.json /app/sources.json
COPY model-support.json /app/model-support.json
COPY --from=builder /presets /app/presets
COPY --from=builder /out/wowsimcli-classic /usr/local/bin/wowsimcli-classic
COPY --from=builder /out/wowsimcli-tbc /usr/local/bin/wowsimcli-tbc
COPY --from=builder /out/wowsimcli-wotlk /usr/local/bin/wowsimcli-wotlk

ENV WOWSIMS_MANIFEST=/app/sources.json \
    WOWSIMS_LISTEN=0.0.0.0:8092 \
    WOWSIMS_TIMEOUT_SECONDS=45 \
    WOWSIMS_GOMAXPROCS=2 \
    WOWSIMS_MAX_CONCURRENT=2 \
    WOWSIMS_PRESET_ROOT=/app/presets \
    WOWSIMS_REQUIRE_PRESETS=1

EXPOSE 8092
USER 10001

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8092/health', timeout=3).read()" || exit 1

CMD ["python", "/app/app.py"]

import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';

const buildTracesEndpoint = (): string => {
  if (process.env.OTEL_EXPORTER_OTLP_TRACES_ENDPOINT) {
    return process.env.OTEL_EXPORTER_OTLP_TRACES_ENDPOINT;
  }

  if (process.env.OTEL_EXPORTER_OTLP_ENDPOINT) {
    const base = process.env.OTEL_EXPORTER_OTLP_ENDPOINT.replace(/\/$/, '');
    return base.endsWith('/v1/traces') ? base : `${base}/v1/traces`;
  }

  return 'http://localhost:4318/v1/traces';
};

const tracesEndpoint = buildTracesEndpoint();
const serviceName = process.env.OTEL_SERVICE_NAME ?? 'realworld-api';

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: tracesEndpoint,
  }),
  serviceName,
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();

const shutdown = async (signal: NodeJS.Signals) => {
  try {
    await sdk.shutdown();
    console.info(`OpenTelemetry shutdown complete (${signal})`);
  } catch (error) {
    console.error('OpenTelemetry shutdown failed', error);
  }
};

process.once('SIGTERM', () => {
  void shutdown('SIGTERM');
});

process.once('SIGINT', () => {
  void shutdown('SIGINT');
});
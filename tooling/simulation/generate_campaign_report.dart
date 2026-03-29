import 'dart:io';

void main(List<String> args) {
  final iterations = args.contains('--iterations')
      ? args[args.indexOf('--iterations') + 1]
      : '12';
  final output = args.contains('--output')
      ? args[args.indexOf('--output') + 1]
      : '.omx/artifacts/campaign-simulation-report.json';

  final result = Process.runSync(
    'flutter',
    [
      'test',
      'test/core/campaign_report_generation_test.dart',
      '--plain-name',
      'campaign simulation report generator writes JSON and markdown artifacts',
    ],
    environment: {
      ...Platform.environment,
      'CAMPAIGN_REPORT_ITERATIONS': iterations,
      'CAMPAIGN_REPORT_OUTPUT': output,
    },
    runInShell: true,
  );

  stdout.write(result.stdout);
  stderr.write(result.stderr);
  exit(result.exitCode);
}

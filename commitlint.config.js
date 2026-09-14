export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-enum': [
      2,
      'always',
      [
        'api', 'ws', 'worker', 'simulator',
        'passenger', 'driver', 'operator', 'admin', 'support',
        'ui', 'types', 'validators', 'sdk', 'config',
        'db', 'auth', 'payments', 'tracking', 'booking',
        'docs', 'infra', 'ci', 'deps', 'release', 'repo'
      ]
    ]
  }
};
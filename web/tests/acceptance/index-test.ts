import { currentURL, visit } from '@ember/test-helpers';
import { module, test } from 'qunit';
import { setupApplicationTest } from 'web/tests/helpers';

module('Acceptance | index', function (hooks) {
  setupApplicationTest(hooks);

  test('redirects to sign in', async function (assert) {
    await visit('/');

    assert.strictEqual(currentURL(), '/sign-in');
  });
});

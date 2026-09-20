import { module, test } from 'qunit';
import { setupTest } from 'web/tests/helpers';
import ApplicationSessionStore from 'web/session-stores/application';

module('Unit | session-store | application', function (hooks) {
  setupTest(hooks);

  test('resolves the application store used outside tests', function (assert) {
    const store = this.owner.lookup('session-store:application');

    assert.true(store instanceof ApplicationSessionStore);
    if (store instanceof ApplicationSessionStore) {
      assert.strictEqual(typeof store.on, 'function');
      assert.strictEqual(typeof store.restore, 'function');
    }
  });
});

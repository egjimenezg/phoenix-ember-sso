import { click, currentURL, visit } from '@ember/test-helpers';
import { module, test } from 'qunit';
import { setupApplicationTest } from 'web/tests/helpers';

module('Acceptance | index', function (hooks) {
  setupApplicationTest(hooks);

  const originalFetch = globalThis.fetch;

  hooks.afterEach(function () {
    globalThis.fetch = originalFetch;
  });

  test('redirects to sign in', async function (assert) {
    globalThis.fetch = () => Promise.resolve(unauthenticatedResponse());

    await visit('/');

    assert.strictEqual(currentURL(), '/sign-in');
  });

  test('shows the authenticated user', async function (assert) {
    globalThis.fetch = (input, init) => {
      const headers =
        input instanceof Request ? input.headers : new Headers(init?.headers);
      assert.strictEqual(headers.get('accept'), 'application/vnd.api+json');

      return Promise.resolve(authenticatedResponse());
    };

    await visit('/');

    assert.strictEqual(currentURL(), '/');
    assert.dom('[data-test-user-email]').hasText('testuser@example.com');
  });

  test('logs out and returns to sign in', async function (assert) {
    let authenticated = true;

    globalThis.fetch = (input, init) => {
      const method = input instanceof Request ? input.method : init?.method;

      if (method === 'DELETE') {
        const headers =
          input instanceof Request ? input.headers : new Headers(init?.headers);
        assert.strictEqual(headers.get('x-csrf-token'), 'test-csrf-token');
        authenticated = false;
        return Promise.resolve(new Response(null, { status: 204 }));
      }

      return Promise.resolve(
        authenticated ? authenticatedResponse() : unauthenticatedResponse()
      );
    };

    await visit('/');
    await click('[data-test-logout]');

    assert.strictEqual(currentURL(), '/sign-in');
  });
});

function authenticatedResponse(): Response {
  return jsonResponse({
    data: {
      type: 'user',
      id: '1',
      attributes: {
        email: 'testuser@example.com',
        firstName: 'Test',
        lastName: 'User',
      },
    },
    meta: { csrfToken: 'test-csrf-token' },
  });
}

function unauthenticatedResponse(): Response {
  return jsonResponse(
    { errors: [{ status: '401', title: 'Not authenticated' }] },
    401
  );
}

function jsonResponse(body: object, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

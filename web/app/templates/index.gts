import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import type SessionService from 'web/services/session';

export default class IndexPage extends Component {
  @service declare session: SessionService;

  get user() {
    return this.session.user;
  }

  @action
  async logout(): Promise<void> {
    await this.session.invalidate();
  }

  <template>
    <main class="session-page">
      <section class="session-card">
        <p class="session-eyebrow">Authenticated session</p>
        <h1>Welcome, {{this.user.firstName}}</h1>
        <p class="text-muted" data-test-user-email>{{this.user.email}}</p>

        <button
          type="button"
          class="btn btn-primary"
          data-test-logout
          {{on "click" this.logout}}
        >
          Log out
        </button>
      </section>
    </main>
  </template>
}

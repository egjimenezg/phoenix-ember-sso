import Route from '@ember/routing/route';
import type RouterService from '@ember/routing/router-service';
import { service } from '@ember/service';
import type SessionService from 'web/services/session';

export default class SignInRoute extends Route {
  @service declare router: RouterService;
  @service declare session: SessionService;

  async beforeModel(): Promise<void> {
    const isAuthenticated = await this.session.authenticateWithCookie();

    if (isAuthenticated) {
      this.router.replaceWith('index');
    }
  }
}

import Service from 'ember-simple-auth/services/session';
import type RouterService from '@ember/routing/router-service';
import { service } from '@ember/service';
import type Store from 'web/services/store';

export interface SessionUser {
  id: string;
  email: string;
  firstName: string;
  lastName: string | null;
}

interface SessionData {
  authenticated: {
    authenticator?: string;
    csrfToken?: string;
    userId?: string;
    user?: SessionUser;
  };
}

export default class SessionService extends Service<SessionData> {
  @service declare router: RouterService;
  @service declare store: Store;

  get user(): SessionUser {
    const user = this.data.authenticated.user;

    if (!user) {
      throw new Error('The authenticated user is missing from the session.');
    }

    return user;
  }

  async authenticateWithCookie(): Promise<boolean> {
    if (this.isAuthenticated) {
      return true;
    }

    try {
      await this.authenticate('authenticator:oauth');
      return true;
    } catch {
      return false;
    }
  }

  override handleInvalidation(): void {
    this.store.unloadAll();
    this.router.replaceWith('sign-in');
  }
}

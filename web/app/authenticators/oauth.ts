import {
  withReactiveResponse,
  withResponseType,
} from '@warp-drive/core/request';
import { SkipCache } from '@warp-drive/core/types/request';
import { query } from '@warp-drive/utilities/json-api';
import Base from 'ember-simple-auth/authenticators/base';
import { service } from '@ember/service';
import config from 'web/config/environment';
import type { SessionUser } from 'web/services/session';
import type Store from 'web/services/store';

export default class OAuthAuthenticator extends Base {
  @service declare store: Store;

  async restore(): Promise<SessionResponse> {
    return this.fetchSession();
  }

  async authenticate(): Promise<SessionResponse> {
    return this.fetchSession();
  }

  async invalidate(data: SessionResponse): Promise<void> {
    await this.store.request(
      withResponseType<null>({
        url: this.sessionUrl,
        method: 'DELETE',
        headers: new Headers({ 'x-csrf-token': data.csrfToken }),
        credentials: 'include',
        cacheOptions: { [SkipCache]: true },
      })
    );
  }

  private get sessionUrl(): string {
    const apiHost = typeof config.apiHost === 'string' ? config.apiHost : '';
    return `${apiHost}/api/session`;
  }

  private async fetchSession(): Promise<SessionResponse> {
    const apiHost = typeof config.apiHost === 'string' ? config.apiHost : '';

    const document = await this.store.request(
      withReactiveResponse<SessionUser>({
        ...query(
          'user',
          {},
          {
            host: apiHost,
            resourcePath: 'api/session',
            reload: true,
          }
        ),
        credentials: 'include',
      })
    );

    const csrfToken = document.content.meta?.csrfToken;

    if (typeof csrfToken !== 'string') {
      throw new Error('The session response did not include a CSRF token.');
    }

    return {
      csrfToken,
      userId: document.content.data.id,
      user: document.content.data,
    };
  }
}

interface SessionResponse {
  csrfToken: string;
  userId: string;
  user: SessionUser;
}

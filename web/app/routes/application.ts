import Route from '@ember/routing/route';
import { service } from '@ember/service';
import type SessionService from 'web/services/session';

export default class ApplicationRoute extends Route {
  @service declare session: SessionService;

  async beforeModel(): Promise<void> {
    await this.session.setup();
  }
}

import Base from 'ember-simple-auth/authenticators/base';
import { service } from '@ember/service';
import type Store from 'web/services/store';

export default class OAuthAuthenticator extends Base {
  @service declare store: Store;
}

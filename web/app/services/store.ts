import { useLegacyStore } from '@warp-drive/legacy';
import { JSONAPICache } from '@warp-drive/json-api';
import UserSchema from 'web/schemas/user';

const Store = useLegacyStore({
  linksMode: false,
  cache: JSONAPICache,
  schemas: [UserSchema],
});

type Store = InstanceType<typeof Store>;

export default Store;

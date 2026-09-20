import type { ResourceSchema } from '@warp-drive/core/types/schema/fields';

export const UserSchema = {
  type: 'user',
  identity: {
    kind: '@id',
    name: 'id',
  },
  fields: [
    { kind: 'field', name: 'firstName' },
    { kind: 'field', name: 'middleName' },
    { kind: 'field', name: 'lastName' },
    { kind: 'field', name: 'secondLastName' },
    { kind: 'field', name: 'email' },
  ],
} satisfies ResourceSchema;

export default UserSchema;

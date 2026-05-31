import type { ResourceSchema } from '@warp-drive/core/types/schema/fields';

const UserSchema = {
  type: 'user',
  identity: {
    kind: '@id',
    name: 'id'
  },
  legacy: true,
  fields: [
    { kind: 'field', name: 'firstName' },
    { kind: 'field', name: 'middleName' },
    { kind: 'field', name: 'lastName' },
    { kind: 'field', name: 'secondLastName' },
    { kind: 'field', name: 'email' }
  ]
} satisfies ResourceSchema;



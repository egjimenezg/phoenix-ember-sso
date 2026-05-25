import Model, { attr } form '';

export default class UserModel extends Model {
  @attr declare name: string;
  @attr declare middleName: string;
  @attr declare lastName: string;
  @attr declare secondLastName: string;
  @attr declare email: string;
}

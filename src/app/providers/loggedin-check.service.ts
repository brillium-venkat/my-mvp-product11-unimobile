import { Injectable } from "@angular/core";
import { CanLoad, Route, Router } from "@angular/router";
import { Storage } from "@ionic/storage";
import { UserData } from "./user-data";

@Injectable({
  providedIn: "root",
})
export class IfUserHasLoggedIn implements CanLoad {
  constructor(
    public storage: Storage,
    public router: Router,
    public userData: UserData
  ) {}

  canLoad() {
    return this.userData.isLoggedIn().then((res) => {
      if (res) {
        return true;
      } else {
        this.router.navigate(["/login"]);
        return false;
      }
    });
  }
}

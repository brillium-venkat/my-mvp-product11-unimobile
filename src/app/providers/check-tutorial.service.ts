import { Injectable } from "@angular/core";
import { CanLoad, Router } from "@angular/router";
import { Storage } from "@ionic/storage";
import { UserData } from "./user-data";
@Injectable({
  providedIn: "root",
})
export class CheckTutorial implements CanLoad {
  constructor(
    private storage: Storage,
    private router: Router,
    private userData: UserData
  ) {}

  canLoad() {
    return this.storage.get("ion_did_tutorial").then((res) => {
      if (res) {
        if (this.userData.isLoggedIn()) {
          this.router.navigate(["/app", "tabs", "schedule"]);
        } else {
          this.router.navigateByUrl("/login", { replaceUrl: true });
        }
        return false;
      } else {
        return true;
      }
    });
  }
}

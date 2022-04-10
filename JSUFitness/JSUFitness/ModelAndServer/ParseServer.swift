//
//  ParseServer.swift
//  JSUFitness
//
//  Created by Chao Jiang on 3/28/22.
//

import Foundation
import Parse

enum Role: String {
    case Coach = "Coach"
    case Athlete = "Athlete"
}

struct ParseServerComm {
    
    /**
     Sign up as Coach
     - parameter theCoach: Coach
     - parameter completion: (()->())? This clouser will invoke after successfully saved new coach in server
     */
    static func coachSignUp(theCoach: Coach, completion: (()->())? = nil) {
        let coach = PFObject(className: "Coach")
        guard let type = theCoach.type else {
            print("failed to get sports type to let new coach sign up")
            return
        }
        coach["class"] = type
        userSignUp(theUser: theCoach.user) {
            coach["user"] = PFUser.current()!
            coach.saveInBackground { success, error in
                if success {
                    print("successfully saved coach \(theCoach.user.username)")
                    completion?()
                } else {
                    print("failed to save coach: \(theCoach.user.username)")
                }
            }
        }
    }
    
    /**
     Sign up as Athlete
     - parameter theAthlete: Athlete
     - parameter completion: (()->())? This closure will invoke after successfully saved new Athlete in server
     */
    static func athleteSignUp(theAthlete: Athlete, completion: (()->())? = nil) {
        let athlete = PFObject(className: "Athlete")
        guard let type = theAthlete.type else {
            print("failed to get sports type to let new athlete sign up")
            return
        }
        athlete["class"] = type
        userSignUp(theUser: theAthlete.user) {
            athlete["user"] = PFUser.current()!
            athlete.saveInBackground { succeed, error in
                if succeed {
                    print("successfully saved athlete \(theAthlete.user.username)")
                    completion?()
                } else {
                    print("failed to save athlete \(theAthlete.user.username)")
                }
            }
        }
    }
    
    /**
     Post a new Event on server by Coach
     - parameter theEvent: Event
     - parameter athletes: [Athlete] a list of athlete that are required to attend the event
     - parameter completion: (()->())? This closure will invoke after successfully saved new event in server
     - Description: This function will update both Event and AthleteEventAttendance class on database
     */
    static func NewEventPostByCoach(theEvent: Event, athletes: [Athlete], completion: (()->())? = nil) {
        let event = PFObject(className: "Event")
        event["title"] = theEvent.title
        event["time"] = theEvent.time
        event["place"] = theEvent.place
        event["detail"] = theEvent.detail
        getCurrentUserWithRole(role: .Coach) { coach in
            event["coach"] = coach
            event.saveInBackground { succeed, error in
                if succeed {
                    print("The event: \(theEvent.title) successfully created")
                    for athlete in athletes {
                        let athleteEventAttendance = PFObject(className: "AthleteEventAttendance")
                        athleteEventAttendance["event"] = event
                        getAthlete(by: athlete.user.username) { ath in
                            athleteEventAttendance["athlete"] = ath
                            athleteEventAttendance["confirmedByAthlete"] = false
                            athleteEventAttendance.saveInBackground { succeed, error in
                                if succeed {
                                    print ("successfully saved a athleteEventAttendance with event title\(theEvent.title), athlete username: \(athlete.user.username)")
                                } else {
                                    print("failed to save a athleteEventAttendance with event title\(theEvent.title), athlete username: \(athlete.user.username)")
                                }
                            }
                        }
                    }
                    completion?()
                } else {
                    print("failed to create the event: \(theEvent.title)")
                }
            }
        }
        
    }
    
    
    /**
     Post a new team on server by coach
     - parameter theTeam: Team
     - parameter completion: (()->())? This closure will invoke after successfully saved new team in database
     - Description This function will check if there is already a team with the same name as the new team, if so, the new team will not be created. If not, it will start post new team to the database
     */
    static func NewTeamPostedBycoach(theTeam: Team, completion:(()->())? = nil) {
        getTeamWithName(theTeam: theTeam) { team in
            print("There is already a team with name: \(theTeam.name)")
        } failedWithNoNameMatch: {
            let team = PFObject(className: "Team")
            team["name"] = theTeam.name
            getCurrentUserWithRole(role: .Coach) { coach in
                team["coach"] = coach
                team.saveInBackground { success, error in
                    if success {
                        print("successfully create a new team with team name \(theTeam.name)")
                        completion?()
                    } else {
                        print("failed to create a new team with name \(theTeam.name)")
                    }
                }
            }
        }
    }
    
    static func initialTeamMembersPostedByCoach(theTeam: Team, theAthletes: [Athlete], completion:(()->())? = nil) {
        ParseServerComm.getTeamWithName(theTeam: theTeam, completion: { team in
            var usernames = [String]()
            for athlete in theAthletes {
                usernames.append(athlete.user.username)
            }
            let query = PFUser.query()
            query?.whereKey("username", containedIn: usernames)
            query?.findObjectsInBackground(block: { PFObjects, error in
                if let users = PFObjects {
                    let innerQuery = PFQuery(className: "Athlete")
                    innerQuery.whereKey("user", containedIn: users)
                    innerQuery.findObjectsInBackground { PFObjects, error in
                        if let athletes = PFObjects {
                            for athlete in athletes {
                                athlete["team"] = team
                            }
                            PFObject.saveAll(inBackground: athletes) { succeed, error in
                                if succeed {
                                    completion?()
                                } else {
                                    print("Failed to add those athletes to the team.")
                                }
                            }
                        }
                        
                    }
                }
            })
        })
    }
    
    
    /**
     Get a team PFObject that fits required team name
     - parameter theTeam: Team
     - parameter completion: ((PFObject)->())? the closure that will be invoked when successfully found the team to return the team
     - parameter failedWithNoNameMatch: (()->())? the closure that will be invoked when there is no name match team found in database
     */
    static func getTeamWithName(theTeam: Team, completion: ((PFObject)->())? = nil, failedWithNoNameMatch: (()->())? = nil) {
        let teamQuery = PFQuery(className: "Team")
        teamQuery.whereKey("name", equalTo: theTeam.name)
        teamQuery.findObjectsInBackground { teams, error in
            if let teams = teams {
                if let team = teams.first {
                    print("found team with name: \(theTeam.name)")
                    completion?(team)
                } else if teams.count == 0{
                    failedWithNoNameMatch?()
                }
            }
        }
    }
    
    
    /**
     Add a athlete to a team by update athlete["team"] in Athlete entity
     - parameter theTeam: Team
     - parameter theAthlete: Athlete
     */
    static func coachUpdateTeamWithAddingNewAthlete(theTeam: Team, theAthlete: Athlete, completion: ((Bool)->())? = nil) {
        // get pfobject for the athlete
        getAthlete(by: theAthlete.user.username) { athlete in
            // get team with team name
            getTeamWithName(theTeam: theTeam, completion: { team in
                athlete["team"] = team
                //save info into athlete PFObject
                athlete.saveInBackground { success, error in
                    if success {
                        print("Successfully updated Athlete(\(theAthlete.user.username)'s team(\(theTeam.name))")
                        completion?(true)
                    } else {
                        print("failed to update athlete(\(theAthlete.user.username)'s team(\(theTeam.name)")
                        completion?(false)
                    }
                }
            })
        }
    }
    
    
    
    
    /**
     return a list of athletes that have not been signed to any team
     */
    static func getUnsignedAthletesPortraitAndFName(completion: (([Athlete])->())? = nil) {
        
        var theAthletes = [Athlete]()
        
        let query = PFQuery(className: "Athlete")
        query.whereKeyDoesNotExist("team")
        query.findObjectsInBackground { objects, error in
            if let athletes = objects {
                var ids: [String] = []
                for athlete in athletes {
                    if let user = athlete["user"] as? PFUser {
                        if let objectId = user.objectId {
                            ids.append(objectId)
                        }
                    }
                }
                
                let innerQuery = PFUser.query()!
                innerQuery.whereKey("objectId", containedIn: ids)
                innerQuery.findObjectsInBackground { objects, error in
                    if let users = objects {
                        for user in users {
                            if let u = user as? PFUser {
                                var theUser = User(username: u.username!)
                                guard let fName = u.object(forKey: "first") as? String else {return}
                                theUser.firstName = fName
                                guard let portraitImagefile = user.object(forKey: "portrait") as? PFFileObject else {return}
                                guard let portraitImageUrlStr = portraitImagefile.url else {return}
                                guard let portraitUrl = URL(string: portraitImageUrlStr) else {return}
                                theUser.portraitUrl = portraitUrl
                                theUser.id = u.objectId
                                let athlete = Athlete(user: theUser)
                                theAthletes.append(athlete)
                            }
                        }
                        completion?(theAthletes)
                    }
                }
                
            } else {
                print("Did not find any matched athletes")
            }
        }
    }
    
}


//MARK: - private help functions
extension ParseServerComm {
    
    private static func userSignUp(theUser: User, succeed: (()->())? = nil) {
        let user = PFUser()
        user.username = theUser.username
        user.password = theUser.password!
        user.email = theUser.email!
        user["first"] = theUser.firstName!
        user["last"] = theUser.lastName!
        if let portraitFile = imageConvert(for: theUser.portrait!) {
            user["portrait"] = portraitFile
        }
        user["phone"] = theUser.phone
        user.signUpInBackground { success, error in
            if success {
                print("successfully saved user: \(theUser.username)")
                succeed?()
            } else {
                print("failed to save user: \(theUser.username)")
            }
        }
    }
    
    private static func imageConvert(for image: UIImage) -> PFFileObject? {
        guard let imageData = image.pngData() else {
            print("Failed to convert image by .pngData()")
            return nil
        }
        let imageFile = PFFileObject(name: "portrait", data: imageData)
        return imageFile
    }
    
    
    /**
     Get current logined user's role object from server (eg: Coach, Athlete)
     - parameter role: Role -- An enum type to let you choose which role object you need to access from server
     - parameter completion: (()->())? This closure will invoke after successfully found the role object in database
     */
    private static func getCurrentUserWithRole(role: Role, completion: @escaping (PFObject)->()) {
        let query = PFQuery(className: role.rawValue)
        query.whereKey("user", equalTo: PFUser.current()!)
        query.findObjectsInBackground() { objects, error in
            if let roles = objects {
                if let role = roles.first {
                    print("successfully found current user with role")
                    completion(role)
                }
            } else {
                print("Failed to find \(role.rawValue)")
            }
            
        }
    }
    
    private static func getAthlete(by username: String, completion: @escaping ((PFObject)->())) {
        let innerQuery = PFUser.query()!
        innerQuery.whereKey("username", equalTo: username)
        let query = PFQuery(className: "Athlete")
        query.whereKey("user", matchesQuery: innerQuery)
        query.findObjectsInBackground() { objects, error in
            if let athletes = objects {
                if let athlete = athletes.first {
                    print("successfully found athlete by username: \(username)")
                    completion(athlete)
                } else {
                    print("No athlete has been fount")
                }
            } else {
                print("Failed to find athlete by his/her username: \(username)")
            }
        }
        
    }
    
}

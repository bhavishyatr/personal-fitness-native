import Foundation

enum WorkoutCatalog {
    static let workouts: [WorkoutPlan] = [
        WorkoutPlan(
            id: "full-body-strength",
            title: "Full Body Strength",
            summary: "A balanced strength session that trains the major muscle groups.",
            category: .strength,
            durationMinutes: 35,
            difficulty: .intermediate,
            equipment: ["Dumbbells"],
            focusAreas: ["Legs", "Chest", "Back", "Shoulders"],
            exercises: [
                WorkoutExercise(
                    id: "goblet-squat",
                    name: "Goblet Squat",
                    target: "3 sets × 10 reps",
                    instruction: "Keep your chest tall and sit your hips down between your knees."
                ),
                WorkoutExercise(
                    id: "dumbbell-row",
                    name: "Dumbbell Row",
                    target: "3 sets × 10 reps each side",
                    instruction: "Brace your torso and pull the dumbbell toward your hip."
                ),
                WorkoutExercise(
                    id: "floor-press",
                    name: "Dumbbell Floor Press",
                    target: "3 sets × 10 reps",
                    instruction: "Lower with control until your upper arms lightly touch the floor."
                ),
                WorkoutExercise(
                    id: "romanian-deadlift",
                    name: "Romanian Deadlift",
                    target: "3 sets × 10 reps",
                    instruction: "Push your hips back while keeping the weights close to your legs."
                ),
                WorkoutExercise(
                    id: "shoulder-press",
                    name: "Shoulder Press",
                    target: "3 sets × 8 reps",
                    instruction: "Press overhead without arching your lower back."
                )
            ]
        ),
        WorkoutPlan(
            id: "upper-body-strength",
            title: "Upper Body Strength",
            summary: "Build pushing and pulling strength across your chest, back, arms, and shoulders.",
            category: .strength,
            durationMinutes: 30,
            difficulty: .intermediate,
            equipment: ["Dumbbells"],
            focusAreas: ["Chest", "Back", "Arms", "Shoulders"],
            exercises: [
                WorkoutExercise(
                    id: "incline-push-up",
                    name: "Incline Push-Up",
                    target: "3 sets × 12 reps",
                    instruction: "Keep a straight line from your shoulders through your heels."
                ),
                WorkoutExercise(
                    id: "one-arm-row",
                    name: "One-Arm Dumbbell Row",
                    target: "3 sets × 10 reps each side",
                    instruction: "Drive your elbow back and keep your shoulder away from your ear."
                ),
                WorkoutExercise(
                    id: "lateral-raise",
                    name: "Lateral Raise",
                    target: "3 sets × 12 reps",
                    instruction: "Raise the weights only to shoulder height with soft elbows."
                ),
                WorkoutExercise(
                    id: "biceps-curl",
                    name: "Biceps Curl",
                    target: "3 sets × 10 reps",
                    instruction: "Keep your elbows close to your sides throughout the movement."
                ),
                WorkoutExercise(
                    id: "triceps-extension",
                    name: "Overhead Triceps Extension",
                    target: "3 sets × 10 reps",
                    instruction: "Keep your upper arms steady as you extend your elbows."
                )
            ]
        ),
        WorkoutPlan(
            id: "hiit-express",
            title: "HIIT Express",
            summary: "Short work intervals with recovery periods for a fast full-body session.",
            category: .hiit,
            durationMinutes: 20,
            difficulty: .advanced,
            equipment: [],
            focusAreas: ["Full Body", "Conditioning"],
            exercises: [
                WorkoutExercise(
                    id: "jumping-jacks",
                    name: "Jumping Jacks",
                    target: "40 sec work · 20 sec rest",
                    instruction: "Move at a pace you can control while landing softly."
                ),
                WorkoutExercise(
                    id: "bodyweight-squat",
                    name: "Bodyweight Squat",
                    target: "40 sec work · 20 sec rest",
                    instruction: "Keep your knees tracking in line with your toes."
                ),
                WorkoutExercise(
                    id: "mountain-climber",
                    name: "Mountain Climbers",
                    target: "40 sec work · 20 sec rest",
                    instruction: "Keep your shoulders stacked over your wrists."
                ),
                WorkoutExercise(
                    id: "reverse-lunge",
                    name: "Alternating Reverse Lunge",
                    target: "40 sec work · 20 sec rest",
                    instruction: "Step back far enough to keep the front foot planted."
                ),
                WorkoutExercise(
                    id: "high-knees",
                    name: "High Knees",
                    target: "40 sec work · 20 sec rest",
                    instruction: "Stay tall and use a controlled, quick rhythm."
                )
            ]
        ),
        WorkoutPlan(
            id: "brisk-cardio-walk",
            title: "Brisk Cardio Walk",
            summary: "A simple walking workout with pace changes to build aerobic endurance.",
            category: .cardio,
            durationMinutes: 30,
            difficulty: .beginner,
            equipment: [],
            focusAreas: ["Cardio", "Endurance"],
            exercises: [
                WorkoutExercise(
                    id: "walk-warmup",
                    name: "Easy Walk",
                    target: "5 minutes",
                    instruction: "Start at a relaxed pace and gradually increase your stride."
                ),
                WorkoutExercise(
                    id: "walk-brisk-1",
                    name: "Brisk Walk",
                    target: "8 minutes",
                    instruction: "Walk quickly enough to feel challenged while maintaining control."
                ),
                WorkoutExercise(
                    id: "walk-easy",
                    name: "Recovery Walk",
                    target: "3 minutes",
                    instruction: "Reduce your pace and let your breathing settle."
                ),
                WorkoutExercise(
                    id: "walk-brisk-2",
                    name: "Brisk Walk",
                    target: "9 minutes",
                    instruction: "Return to a purposeful pace with relaxed shoulders."
                ),
                WorkoutExercise(
                    id: "walk-cooldown",
                    name: "Cool Down",
                    target: "5 minutes",
                    instruction: "Gradually slow your pace before finishing."
                )
            ]
        ),
        WorkoutPlan(
            id: "core-stability",
            title: "Core Stability",
            summary: "Controlled core work focused on trunk strength and stability.",
            category: .core,
            durationMinutes: 20,
            difficulty: .beginner,
            equipment: ["Mat"],
            focusAreas: ["Core", "Stability"],
            exercises: [
                WorkoutExercise(
                    id: "dead-bug",
                    name: "Dead Bug",
                    target: "3 sets × 8 reps each side",
                    instruction: "Keep your lower back gently supported as opposite limbs extend."
                ),
                WorkoutExercise(
                    id: "bird-dog",
                    name: "Bird Dog",
                    target: "3 sets × 8 reps each side",
                    instruction: "Reach long without rotating your hips."
                ),
                WorkoutExercise(
                    id: "forearm-plank",
                    name: "Forearm Plank",
                    target: "3 × 30 seconds",
                    instruction: "Keep your ribs and hips stacked in a straight line."
                ),
                WorkoutExercise(
                    id: "side-plank",
                    name: "Side Plank",
                    target: "2 × 20 seconds each side",
                    instruction: "Press the floor away and keep your hips lifted."
                )
            ]
        ),
        WorkoutPlan(
            id: "morning-yoga-flow",
            title: "Morning Yoga Flow",
            summary: "A gentle sequence to wake up the body and move through a comfortable range.",
            category: .yoga,
            durationMinutes: 25,
            difficulty: .beginner,
            equipment: ["Mat"],
            focusAreas: ["Mobility", "Balance", "Breathing"],
            exercises: [
                WorkoutExercise(
                    id: "cat-cow",
                    name: "Cat-Cow",
                    target: "8 slow rounds",
                    instruction: "Move with your breath through a comfortable spinal range."
                ),
                WorkoutExercise(
                    id: "downward-dog",
                    name: "Downward Dog",
                    target: "45 seconds",
                    instruction: "Lengthen your spine and keep a soft bend in your knees if needed."
                ),
                WorkoutExercise(
                    id: "low-lunge",
                    name: "Low Lunge",
                    target: "45 seconds each side",
                    instruction: "Keep the front knee aligned over the ankle."
                ),
                WorkoutExercise(
                    id: "warrior-two",
                    name: "Warrior II",
                    target: "30 seconds each side",
                    instruction: "Reach through both arms while keeping your torso tall."
                ),
                WorkoutExercise(
                    id: "childs-pose",
                    name: "Child's Pose",
                    target: "60 seconds",
                    instruction: "Relax into the position and breathe slowly."
                )
            ]
        ),
        WorkoutPlan(
            id: "mobility-reset",
            title: "Mobility Reset",
            summary: "A low-intensity routine for hips, shoulders, and spine after a long day.",
            category: .mobility,
            durationMinutes: 15,
            difficulty: .beginner,
            equipment: [],
            focusAreas: ["Hips", "Shoulders", "Spine"],
            exercises: [
                WorkoutExercise(
                    id: "neck-rotation",
                    name: "Gentle Neck Rotation",
                    target: "5 reps each direction",
                    instruction: "Use a slow, comfortable range without forcing the movement."
                ),
                WorkoutExercise(
                    id: "shoulder-circles",
                    name: "Shoulder Circles",
                    target: "10 reps each direction",
                    instruction: "Make smooth circles while keeping your ribs relaxed."
                ),
                WorkoutExercise(
                    id: "open-book",
                    name: "Open Book",
                    target: "8 reps each side",
                    instruction: "Rotate through your upper back while keeping your knees together."
                ),
                WorkoutExercise(
                    id: "hip-90-90",
                    name: "90/90 Hip Switch",
                    target: "8 slow reps",
                    instruction: "Move between sides under control and stay within a comfortable range."
                ),
                WorkoutExercise(
                    id: "ankle-rock",
                    name: "Ankle Rocks",
                    target: "10 reps each side",
                    instruction: "Drive the knee forward while keeping the heel down."
                )
            ]
        )
    ]
}

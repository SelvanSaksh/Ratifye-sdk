import UIKit

final class RatifyeGalleryPickerPresenter: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var onImagePicked: ((UIImage) -> Void)?
    var onCancelled: (() -> Void)?

    func present(from view: UIView) {
        guard let host = view.ratifyeParentViewController() else { return }

        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.image"]
        picker.delegate = self
        host.present(picker, animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        onCancelled?()
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            onImagePicked?(image)
        } else {
            onCancelled?()
        }
    }
}
